class StageCollection
  extend Forwardable
  include Enumerable

  attr_reader :stages

  def_delegators :@stages, :each, :second, :last, :size

  def initialize(stages, object)
    @object = object
    @stages = initialize_stages(stages)
  end

  def previous_stage(stage)
    path = path_until(stage)
    return if path.length <= 1
    path[path.length - 2]
  end

  def next_stage(stage)
    find_stage(find_stage(stage)&.first_valid_transition)
  end

  def path_until(stage)
    return [] unless stage
    loop_stage = stages.first
    path = [loop_stage]
    until loop_stage.nil? || loop_stage == stage
      loop_stage = next_stage(loop_stage)
      path << loop_stage if loop_stage
    end
    path.include?(stage) ? path : []
  end

  private

  def initialize_stages(stages)
    stages.map do |stage|
      Stage.new(
        name: stage[:name],
        transitions: stage[:transitions],
        dependencies: stage[:dependencies],
        object: @object
      )
    end
  end

  def find_stage(stage_name)
    stages.find { |stage| stage.name == stage_name&.to_sym }
  end
end
