module TonSdkRubySmc
  def require_type(name, value, type)
    raise "#{name} must be #{type}" unless value.is_a?(type)
  end
end