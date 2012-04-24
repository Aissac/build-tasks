require File.dirname(__FILE__) + '/helpers'
require File.dirname(__FILE__) + '/git_helpers'
require File.dirname(__FILE__) + '/gems'

class Build
  include Helpers
  include GitHelpers
  
  class << self
    def release_current_branch
      new("Release current branch").release_current_branch
    end
    
    def update_latest_gems
      new("Update latest gems").update_latest_gems
    end
    
    def commit_and_push_current_branch
      new("Push current branch").commit_and_push_current_branch
    end
  end
  
  def initialize(name)
    @name = name
  end
  
  def release_current_branch
    validate_working_copy!
    
    push_current_branch
    merge_current_branch_into_master
    bump_version
    release_gem
  end
  
  def update_latest_gems
    validate_working_copy!
    Gems.update!
  end
  
  def commit_and_push_current_branch
    commit("Updated bundle.")
    push_current_branch
  end
  
  private
    def validate_working_copy!
      abort("Do not run this on the master branch.") if master_branch_current?
      abort("Uncommitted changes.") unless clean_staging_area?
      abort("Master heads not in sync. Pull into master branch from origin/master.") unless master_heads_in_sync?
      abort("Master branch not merged into current branch.") unless master_merged?
    end
    
    def release_gem
      rake 'git:release'
    end
  
    def merge_current_branch_into_master
      name = current_branch_name
      git.checkout('master')
      git.merge(name)
    rescue Git::GitExecuteError => e
      abort(e.message)
    end
  
    def bump_version
      rake 'version:bump:minor'
      rake 'gemspec'
      commit 'Regenerated gemspec.'
    end
  
    def rake(task)
      Rake::Task[task].invoke
    end
    
    def root
      File.expand_path File.dirname(__FILE__) + "/../../"
    end
end
