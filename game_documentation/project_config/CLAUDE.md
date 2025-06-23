# Claude Code Development Notes

## GPUParticles2D in Godot 4.4 - SOLUTION DOCUMENTED

### Problem
When upgrading to Godot 4.4, GPUParticles2D properties like `direction`, `spread`, and `color` cannot be set directly on the particle node:

```gdscript
# ❌ BROKEN - Direct property access
particles.direction = Vector3(1, 0, 0)
particles.spread = 45.0
particles.color = Color.RED
# Error: Invalid assignment of property 'direction' with value of type 'Vector3'
```

### Solution
Use `ParticleProcessMaterial` resource to control particle properties:

```gdscript
# ✅ CORRECT - ParticleProcessMaterial approach
# Ensure we have a ParticleProcessMaterial
if not particles.process_material:
    particles.process_material = ParticleProcessMaterial.new()

var material = particles.process_material as ParticleProcessMaterial
if material:
    material.direction = Vector3(1, 0, 0)
    material.spread = 45.0
    material.color = Color.RED
```

### Scene File Updates
Also update `.tscn` files to use proper ParticleProcessMaterial:

```
[sub_resource type="ParticleProcessMaterial" id="ParticleProcessMaterial_1"]
direction = Vector3(0, -1, 0)
spread = 45.0
color = Color(1, 0.8, 0.2, 1)

[node name="Particles" type="GPUParticles2D"]
process_material = SubResource("ParticleProcessMaterial_1")
```

### Key Properties Available
- `direction: Vector3` - Emission direction
- `spread: float` - Angle spread in degrees
- `color: Color` - Base particle color
- `initial_velocity_min/max: float` - Speed range
- `gravity: Vector3` - Gravity effect
- `scale_min/max: float` - Size variation

This approach works for both runtime creation and pre-built scene files.

## Combat Logic Documentation

### Health System
- Player: 5 HP, 3 Defense Points
- Enemy: 5 HP, 1 Defense Point
- Defense points reduce incoming damage
- Stun system with 3-second duration

### Rock-Paper-Scissors Combat
- Rock beats Scissors
- Paper beats Rock  
- Scissors beats Paper
- Neutral stance provides damage reduction

### AI State Machine
Enemy states: IDLE, WALKING, LOST_PLAYER, ALERT, OBSERVING, POSITIONING, STANCE_SELECTION, ATTACKING, RETREATING, STUNNED

### Control Scheme
- Arrow keys: Movement
- A/S/D: Rock/Paper/Scissors stances
- Directional attack: Hold stance + arrow + attack

## Asset Information
- Player sprites: 48x48 effective size (400x300 scaled to 0.12)
- Enemy sprites: 42x42 effective size (400x300 scaled to 0.105)
- Pixel art import: `texture_filter=0` for crisp rendering

## Development Workflow
- After every feature done, let me know you finished by playing the notification in global memory and waiting for me to test