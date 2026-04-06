class_name Enum

enum EnumShaderType {
	NONE,
	GLOW,
	GRADIENT
}

enum FlowMode {
	SUPPORT,      ## 应援模式
	SUBTITLE,     ## 字幕模式
	TELEPROMPTER, ## 提词器模式
	DANMAKU,      ## 弹幕模式
	CUSTOM        ## 自定义模式
}

static func get_shader_path(shader_type: EnumShaderType) -> String:
	match shader_type:
		EnumShaderType.GLOW:
			return "res://effects/glow.gdshader"
		EnumShaderType.GRADIENT:
			return "res://effects/gradient.gdshader"
	return ""
