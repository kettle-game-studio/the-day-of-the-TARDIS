extends Node

var report_servoce: SSTReportService
var settings := SSTPluginSettings.new()


func _init() -> void:
	if "--enable-sst-autoload" not in OS.get_cmdline_args():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000

	settings.add_to_project_settings()
	var shader_watcher = SSTShaderWatcher.new(settings.shader_watcher)
	var triggers_collector = FrustumTriggerCollectorService.new(self)
	report_servoce = SSTReportService.new(settings.report, shader_watcher, triggers_collector)


func _process(_delta: float) -> void:
	report_servoce.send_report_if_needed(get_viewport())


class FrustumTriggerCollectorService:
	extends SSTReportService.TriggerCollectorService
	var node: Node


	func _init(node: Node):
		self.node = node


	func collect() -> SSTTriggerCollector:
		collector.add_in_frustum_3d(node.get_tree().root, node.get_viewport().get_camera_3d())
		return collector
