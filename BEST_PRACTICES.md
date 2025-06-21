# Best Practices for Godot Game Development

This document contains key learnings and best practices discovered during the development of Rogue Hands, particularly around coordinate systems, debugging methodology, and visual system implementation.

## Coordinate System Best Practices

### Understanding Parent-Child Relationships

**Key Principle**: Child nodes use coordinate systems relative to their parents.

```gdscript
# ❌ WRONG - Mixing coordinate systems
# Line2D is child of Player, but using global coordinates
add_point(global_position)  # Global coords in local system = offset bug

# ✅ CORRECT - Consistent coordinate system
add_point(Vector2.ZERO)     # Local coords in local system
add_point(relative_vector)  # Relative positioning from parent
```

### Local vs Global Coordinates

**When to use Local Coordinates:**
- Child nodes positioning relative to parent
- UI elements within containers
- Visual effects attached to characters
- Line2D, particles, or other child visual elements

**When to use Global Coordinates:**
- Cross-scene positioning
- Physics collision detection
- Distance calculations between separate objects
- Scene-wide coordinate references

### Vector2.ZERO Pattern

**Best Practice**: Use `Vector2.ZERO` as the local origin for child nodes.

```gdscript
# For Line2D child of character:
add_point(Vector2.ZERO)  # Always starts from character center
add_point(relative_end)  # Direction/distance from character
```

**Why this works:**
- `Vector2.ZERO` represents the parent node's center
- No complex center calculations needed
- Always accurate regardless of parent position
- Cleaner, more maintainable code

## Debugging Methodology

### Systematic Problem Simplification

**Approach**: When facing complex bugs, simplify systematically:

1. **Identify the Core Issue**: Focus on the fundamental problem, not symptoms
2. **Strip Complexity**: Remove advanced features to isolate the issue
3. **Test Assumptions**: Verify what you think you know
4. **Iterate**: Make small changes and test frequently

**Example from this project:**
- Started with complex marker/center calculation system
- Simplified to basic line positioning
- Discovered coordinate system mismatch
- Final solution was simpler than original

### Strategic Debug Logging

**Pattern**: Add debug prints at key decision points:

```gdscript
# Position debugging
print("PLAYER: Entering stance ", Stance.keys()[new_stance], " - Position: ", global_position)

# Calculation debugging  
print("ENEMY: Dash line relative vector: ", relative_target)

# State debugging
if stance_to_dash_timer > stance_to_dash_delay * 0.8:
    print("ENEMY: Early attack phase - showing trajectory")
```

**Benefits:**
- Reveals coordinate mismatches immediately
- Shows actual vs expected values
- Helps track state changes
- Provides clear evidence for troubleshooting

### Root Cause Analysis

**Principle**: Fix the cause, not the symptoms.

**Warning Signs of Symptom Fixing:**
- Adding more complexity to solve positioning issues
- Complex mathematical workarounds for simple problems
- Multiple "correction" factors or offsets
- Code that works but you're not sure why

**Root Cause Indicators:**
- Understanding why the problem exists
- Simple, elegant solutions
- Code that makes logical sense
- Solutions that prevent similar future issues

## Godot-Specific Patterns

### Line2D Best Practices

**Node Hierarchy Impact:**
```
Player (CharacterBody2D)
├── Sprite (AnimatedSprite2D)
├── DashPreview (Line2D)  # Uses Player's coordinate system
└── Other Components
```

**Coordinate Behavior:**
- Line2D inherits parent's coordinate system
- `add_point(Vector2.ZERO)` = parent's center
- `add_point(Vector2(100, 0))` = 100 pixels right of parent

### Scene Structure Considerations

**Best Practice**: Understand how node hierarchy affects positioning:

1. **Visual Nodes as Children**: Attach visual elements (Line2D, particles) as children of the object they relate to
2. **Coordinate Consistency**: Keep coordinate calculations within the same system
3. **Z-Index Management**: Use `z_index` to control rendering order when needed

## Development Philosophy

### Start Simple, Add Complexity Thoughtfully

**Pattern**: Begin with the simplest solution that works:

1. **Minimal Viable Feature**: Get basic functionality working first
2. **Test Early**: Verify the foundation before adding features
3. **Incremental Enhancement**: Add complexity only when simple solutions are insufficient
4. **Refactor Trigger**: When code becomes hard to understand or maintain

### Over-Engineering Warning Signs

**Red Flags:**
- Complex center position calculations when simple relative positioning works
- Multiple coordinate system conversions
- Elaborate workarounds for fundamental misunderstandings
- Code that "works" but requires extensive comments to explain

**Solution:**
- Step back and question the approach
- Look for simpler alternatives
- Understand the underlying system better
- Don't be afraid to restart with a cleaner approach

### When to Refactor vs Rebuild

**Refactor When:**
- Core logic is sound but needs cleanup
- Performance optimizations needed
- Code structure improvements
- Adding new features to existing system

**Rebuild When:**
- Fundamental approach is flawed
- Multiple interconnected bugs
- Code becomes unmaintainable
- Fighting the framework instead of working with it

## Key Technical Patterns

### Coordinate System Pattern
```gdscript
# Child node positioning pattern
func show_visual_effect_from_parent():
    # Always start from parent center
    var start = Vector2.ZERO
    # Calculate relative end position
    var end = direction.normalized() * distance
    # Apply to child visual element
    child_visual.setup(start, end)
```

### Debug Information Pattern
```gdscript
# Strategic debugging pattern
func important_state_change():
    # Log state, position, and key variables
    print("OBJECT: State change - Position: ", global_position, " - New state: ", state)
    # Proceed with logic
    perform_action()
```

### Visual System Pattern
```gdscript
# Child visual element pattern
extends Line2D
class_name VisualHelper

func show_relative_line(relative_end: Vector2):
    clear_points()
    add_point(Vector2.ZERO)    # Parent center
    add_point(relative_end)    # Relative positioning
    visible = true
```

## Lessons from the Dash Line Implementation

### What Worked
- **Systematic debugging**: Position logging revealed the coordinate issue immediately
- **Simplification approach**: Removing complexity led to the solution
- **Understanding the system**: Learning Godot's coordinate behavior was key

### What Didn't Work
- **Complex center calculations**: Over-engineered sprite center detection
- **Global coordinate mixing**: Caused mysterious offset bugs
- **Adding more features**: Markers and visual effects masked the core issue

### Key Insight
**The most elegant solution aligned with Godot's design patterns rather than fighting against them.**

---

## Quick Reference

### Coordinate System Checklist
- [ ] Are you mixing global and local coordinates?
- [ ] Is the visual element a child of the right parent?
- [ ] Are you using Vector2.ZERO for local origin?
- [ ] Do your calculations stay within one coordinate system?

### Debugging Checklist
- [ ] Added position debug logging?
- [ ] Tested the simplest version first?
- [ ] Verified your assumptions about how the system works?
- [ ] Focused on root cause rather than symptoms?

### Visual System Checklist
- [ ] Is the visual element properly parented?
- [ ] Are you using relative positioning?
- [ ] Is the z_index set for proper rendering order?
- [ ] Does the solution feel simple and maintainable?

---

*Remember: The best code is code that works with the framework, not against it.*