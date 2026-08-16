class_name SSTResourceUtils
extends Object


static func is_shader_with_mode(mat: Material, mode: Shader.Mode):
	return mat is ShaderMaterial and (mat as ShaderMaterial).shader.get_mode() == mode


static func make_skinned_quad() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts := [
		Vector3(-0.5, -0.5, 0.0),
		Vector3(0.5, -0.5, 0.0),
		Vector3(0.5, 0.5, 0.0),
		Vector3(-0.5, 0.5, 0.0),
	]

	for v in verts:
		st.set_bones(PackedInt32Array([0, 0, 0, 0]))
		st.set_weights(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		st.add_vertex(v)

	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(0)
	st.add_index(2)
	st.add_index(3)

	return st.commit()
