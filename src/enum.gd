class_name Enum

enum EnumShaderType {
    NONE,
    GLOW,
    GRADIENT
}

func get_path(shader_type: EnumShaderType) -> String:
    match shader_type:
        EnumShaderType.NONE:
            return ""
        EnumShaderType.GLOW:
            return "res://effects/glow.shader"
        EnumShaderType.GRADIENT:
            return "res://effects/gradient.shader"