import bpy

# Define materials
materials = {
    "Red": (1.0, 0.0, 0.0, 1.0),
    "Green": (0.0, 1.0, 0.0, 1.0),
    "Blue": (0.0, 0.0, 1.0, 1.0),
    "Yellow": (1.0, 1.0, 0.0, 1.0),
    "Cyan": (0.0, 1.0, 1.0, 1.0),
    "Magenta": (1.0, 0.0, 1.0, 1.0),
    "White": (1.0, 1.0, 1.0, 1.0),
    "Black": (0.0, 0.0, 0.0, 1.0)
}

# Function to create a material
def create_material(name, color):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Base Color'].default_value = color
    return mat

# Import USD file
bpy.ops.wm.usd_import(filepath="./traina.usda")

# Create materials
created_materials = {}
for name, color in materials.items():
    created_materials[name] = create_material(name, color)

# Assign materials to specific parts of the train
part_material_mapping = {
    "Wheel": "Red",
    "Body": "Yellow",
    "Chassis": "Green",
    "Cabin": "Red",
    "Hub": "Red",
    "Chimney": "Green"
}

for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        material_name = part_material_mapping.get(obj.name, None)
        if material_name:
            obj.data.materials.clear()
            obj.data.materials.append(created_materials[material_name])

# Export the modified USD file
bpy.ops.wm.usd_export(filepath="./modified_train.usda")