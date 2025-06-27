class_name GameConstants
extends RefCounted

## Game Constants for Rogue Hands 2.5D
## Centralized constants following Godot 4.4 best practices
## Replaces magic numbers throughout codebase for better maintainability

# ============================================================================
# PLAYER CONSTANTS
# ============================================================================

## Movement Constants
const PLAYER_SPEED: float = 200.0
const PLAYER_ACCELERATION: float = 800.0
const PLAYER_DECELERATION: float = 1000.0
const MOVEMENT_THRESHOLD: float = 10.0

## Combat Constants  
const PLAYER_DASH_SPEED: float = 600.0
const PLAYER_DASH_DURATION: float = 0.3
const ATTACK_COOLDOWN: float = 1.0
const PARRY_WINDOW_DURATION: float = 0.5
const IMMUNITY_DURATION: float = 0.5

## Health & Defense Constants
const PLAYER_MAX_HEALTH: int = 5
const PLAYER_MAX_DEFENSE_POINTS: int = 3

## Stun System Constants
const STUN_DURATION: float = 3.0

## Long Idle Constants
const LONG_IDLE_DELAY: float = 5.0

## Rotation Constants
const STANCE_ROTATION_SPEED: float = 0.15

# ============================================================================
# ENEMY CONSTANTS (Base values - CSV can override these)
# ============================================================================

## Movement Constants
const ENEMY_SPEED: float = 100.0
const ENEMY_ACCELERATION: float = 400.0
const ENEMY_DECELERATION: float = 600.0
const ENEMY_MOVEMENT_THRESHOLD: float = 5.0

## Combat Constants
const ENEMY_DASH_SPEED: float = 300.0
const ENEMY_DASH_DURATION: float = 0.6
const ENEMY_ATTACK_COOLDOWN: float = 1.2
const MUTUAL_ATTACK_DAMAGE: int = 2
const NEUTRAL_STANCE_DAMAGE: int = 1
const WEAK_STANCE_DAMAGE: int = 2

## Health & Defense Constants
const ENEMY_MAX_HEALTH: int = 5
const ENEMY_MAX_DEFENSE_POINTS: int = 1

## AI Timing Constants (Base values - CSV aggression can modify)
const STANCE_TO_DASH_DELAY: float = 1.0
const STANCE_DECISION_TIMER: float = 0.3
const STANCE_CHANGE_COOLDOWN: float = 0.5
const RETREAT_TIMER: float = 1.0

## Walking Behavior Constants
const ENEMY_WALKING_SPEED: float = 50.0
const DIRECTION_CHANGE_INTERVAL: float = 2.5

## Detection Constants
const BASE_DETECTION_RADIUS: float = 150.0
const ENHANCED_DETECTION_RADIUS: float = 300.0
const ATTACK_RANGE: float = 100.0

## Idle State Constants
const IDLE_DURATION_MIN: float = 2.0
const IDLE_DURATION_MAX: float = 6.0
const LOST_PLAYER_DURATION: float = 2.5
const ALERT_DURATION: float = 1.0

## Debug Constants
const DEBUG_INTERVAL: float = 1.0
const VISION_CHECK_INTERVAL: float = 0.1

# ============================================================================
# COMBAT SYSTEM CONSTANTS
# ============================================================================

## Damage Values
const DAMAGE_NEUTRAL_STANCE: int = 1
const DAMAGE_WINNING_STANCE: int = 2
const DAMAGE_TIE_STANCE: int = 1
const DAMAGE_PERFECT_PARRY: int = 0

## Damage Categories for Visual Feedback
enum DamageCategory { NONE, LIGHT, NORMAL, HEAVY }

# ============================================================================
# PHYSICS & COLLISION CONSTANTS
# ============================================================================

## Collision Detection
const SEPARATION_DISTANCE_THRESHOLD: float = 30.0
const PLAYER_SEPARATION_FORCE: float = 50.0
const ENEMY_SEPARATION_FORCE: float = 40.0

## Attack Area Sizes (Base values - EnemyData can override)
const PLAYER_ATTACK_RADIUS: float = 22.0
const ENEMY_ATTACK_RADIUS: float = 25.0

## Body Collision Sizes
const PLAYER_BODY_COLLISION: Vector2 = Vector2(12, 12)
const ENEMY_BODY_COLLISION: Vector2 = Vector2(26, 21)

# ============================================================================
# UI & VISUAL CONSTANTS  
# ============================================================================

## Screen Shake Constants
const SCREEN_SHAKE_LIGHT: float = 3.0
const SCREEN_SHAKE_NORMAL: float = 8.0
const SCREEN_SHAKE_HEAVY: float = 20.0

const SCREEN_SHAKE_DURATION_SHORT: float = 0.15
const SCREEN_SHAKE_DURATION_NORMAL: float = 0.25
const SCREEN_SHAKE_DURATION_LONG: float = 0.5

## Animation Constants
const ROTATION_TWEEN_DURATION: float = 0.2
const DAMAGE_FEEDBACK_DURATION: float = 0.1

# ============================================================================
# LEVEL & BOUNDARY CONSTANTS
# ============================================================================

## Level Boundaries
const LEVEL_BOUNDARY_LEFT: float = -425.0
const LEVEL_BOUNDARY_RIGHT: float = 425.0
const LEVEL_BOUNDARY_TOP: float = -275.0
const LEVEL_BOUNDARY_BOTTOM: float = 275.0
const BOUNDARY_MARGIN: float = 50.0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Check if position is near level boundaries
static func is_near_boundary(pos: Vector2) -> bool:
	return pos.x < LEVEL_BOUNDARY_LEFT + BOUNDARY_MARGIN or \
		   pos.x > LEVEL_BOUNDARY_RIGHT - BOUNDARY_MARGIN or \
		   pos.y < LEVEL_BOUNDARY_TOP + BOUNDARY_MARGIN or \
		   pos.y > LEVEL_BOUNDARY_BOTTOM - BOUNDARY_MARGIN

## Get level bounds as Rect2
static func get_level_bounds() -> Rect2:
	var width = LEVEL_BOUNDARY_RIGHT - LEVEL_BOUNDARY_LEFT
	var height = LEVEL_BOUNDARY_BOTTOM - LEVEL_BOUNDARY_TOP
	return Rect2(LEVEL_BOUNDARY_LEFT, LEVEL_BOUNDARY_TOP, width, height)