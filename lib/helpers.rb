module Helpers
  def log(message)
    puts "[#{@name}] #{message}"
  end
  
  def abort(message)
    log "Aborting: #{message}"
    exit(1)
  end
end