class EnvChanger
  def initialize(env)
    @env = env
  end

  def change(target)
    target.gsub(/\$(?:(\w+)|\{(\w+)\})/) do |x| 
      @env[$1.to_s || $2.to_s]
    end 
  end
end
