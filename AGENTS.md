# Factory Game development guidance

- The Godot project root is `D:\FactoryGame`.
- Use Godot 4.7.x and GDScript unless the user explicitly chooses another language.
- Keep simulation logic independent from rendering and UI.
- Use typed GDScript where practical.
- The `godot` MCP server may inspect, launch, run, and modify Godot projects. Only pass `D:\FactoryGame` as its project path for this repository.
- Treat `create_scene`, `add_node`, `load_sprite`, `export_mesh_library`, `save_scene`, and `update_project_uids` as write operations. Use them only when the user has requested project changes.
- Do not add plugins or dependencies without user approval.
- Run the project or relevant checks after changes, inspect debug output, and summarize changed files and limitations.
- Do not edit unrelated files.
