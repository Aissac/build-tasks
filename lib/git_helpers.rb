module GitHelpers
  def git
    @git ||= begin
      require 'git'
      Git.open(root)
    end
  end
  
  def master_heads_in_sync?
    git.branches['master'].gcommit.sha == git.branches['remotes/origin/master'].gcommit.sha
  end
  
  def commit(message)
    log "Committing changes to git: '#{message}'"
    git.commit_all(message)
  end
  
  def push_current_branch
    git.push('origin', current_branch_name)
  end
  
  def current_branch
    git.branches[current_branch_name]
  end
  
  def current_branch_name
    git.lib.branch_current
  end
  
  def clean_staging_area?
    `git ls-files --deleted --modified --others --exclude-standard` == ""
  end
  
  def master_branch_current?
    current_branch_name == 'master'
  end
  
  def master_merged?
    branch_merged?('master')
  end
  
  def branch_merged_into_master?(name)
    branch_merged?(name)
  end
  
  def branch_merged?(name)
    result = `git branch --merged`
    result.split("\n").map {|s| s.strip}.include?(name)
  end
end