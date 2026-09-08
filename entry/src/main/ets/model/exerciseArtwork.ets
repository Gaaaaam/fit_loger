import { PartKey } from './types';

export interface ExerciseArtwork {
  id: string;
  card: Resource;
  start: Resource;
  end: Resource;
}

export const EXERCISE_ARTWORK: ExerciseArtwork[] = [
  { id: 'chest_bb_bench', card: $r('app.media.ex_chest_bb_bench_card'), start: $r('app.media.ex_chest_bb_bench_start'), end: $r('app.media.ex_chest_bb_bench_end') },
  { id: 'chest_db_bench', card: $r('app.media.ex_chest_db_bench_card'), start: $r('app.media.ex_chest_db_bench_start'), end: $r('app.media.ex_chest_db_bench_end') },
  { id: 'chest_incline_bench', card: $r('app.media.ex_chest_incline_bench_card'), start: $r('app.media.ex_chest_incline_bench_start'), end: $r('app.media.ex_chest_incline_bench_end') },
  { id: 'chest_fly', card: $r('app.media.ex_chest_fly_card'), start: $r('app.media.ex_chest_fly_start'), end: $r('app.media.ex_chest_fly_end') },
  { id: 'chest_cable_crossover', card: $r('app.media.ex_chest_cable_crossover_card'), start: $r('app.media.ex_chest_cable_crossover_start'), end: $r('app.media.ex_chest_cable_crossover_end') },
  { id: 'chest_dip', card: $r('app.media.ex_chest_dip_card'), start: $r('app.media.ex_chest_dip_start'), end: $r('app.media.ex_chest_dip_end') },
  { id: 'chest_pushup', card: $r('app.media.ex_chest_pushup_card'), start: $r('app.media.ex_chest_pushup_start'), end: $r('app.media.ex_chest_pushup_end') },
  { id: 'chest_decline_bench', card: $r('app.media.ex_chest_decline_bench_card'), start: $r('app.media.ex_chest_decline_bench_start'), end: $r('app.media.ex_chest_decline_bench_end') },
  { id: 'chest_incline_db_press', card: $r('app.media.ex_chest_incline_db_press_card'), start: $r('app.media.ex_chest_incline_db_press_start'), end: $r('app.media.ex_chest_incline_db_press_end') },
  { id: 'chest_decline_db_press', card: $r('app.media.ex_chest_decline_db_press_card'), start: $r('app.media.ex_chest_decline_db_press_start'), end: $r('app.media.ex_chest_decline_db_press_end') },
  { id: 'chest_incline_fly', card: $r('app.media.ex_chest_incline_fly_card'), start: $r('app.media.ex_chest_incline_fly_start'), end: $r('app.media.ex_chest_incline_fly_end') },
  { id: 'chest_machine_press', card: $r('app.media.ex_chest_machine_press_card'), start: $r('app.media.ex_chest_machine_press_start'), end: $r('app.media.ex_chest_machine_press_end') },
  { id: 'chest_pec_deck', card: $r('app.media.ex_chest_pec_deck_card'), start: $r('app.media.ex_chest_pec_deck_start'), end: $r('app.media.ex_chest_pec_deck_end') },
  { id: 'chest_close_pushup', card: $r('app.media.ex_chest_close_pushup_card'), start: $r('app.media.ex_chest_close_pushup_start'), end: $r('app.media.ex_chest_close_pushup_end') },
  { id: 'chest_incline_pushup', card: $r('app.media.ex_chest_incline_pushup_card'), start: $r('app.media.ex_chest_incline_pushup_start'), end: $r('app.media.ex_chest_incline_pushup_end') },
  { id: 'chest_decline_pushup', card: $r('app.media.ex_chest_decline_pushup_card'), start: $r('app.media.ex_chest_decline_pushup_start'), end: $r('app.media.ex_chest_decline_pushup_end') },
  { id: 'chest_pullover', card: $r('app.media.ex_chest_pullover_card'), start: $r('app.media.ex_chest_pullover_start'), end: $r('app.media.ex_chest_pullover_end') },
  { id: 'shoulder_bb_press', card: $r('app.media.ex_shoulder_bb_press_card'), start: $r('app.media.ex_shoulder_bb_press_start'), end: $r('app.media.ex_shoulder_bb_press_end') },
  { id: 'shoulder_db_press', card: $r('app.media.ex_shoulder_db_press_card'), start: $r('app.media.ex_shoulder_db_press_start'), end: $r('app.media.ex_shoulder_db_press_end') },
  { id: 'shoulder_lateral_raise', card: $r('app.media.ex_shoulder_lateral_raise_card'), start: $r('app.media.ex_shoulder_lateral_raise_start'), end: $r('app.media.ex_shoulder_lateral_raise_end') },
  { id: 'shoulder_front_raise', card: $r('app.media.ex_shoulder_front_raise_card'), start: $r('app.media.ex_shoulder_front_raise_start'), end: $r('app.media.ex_shoulder_front_raise_end') },
  { id: 'shoulder_reverse_fly', card: $r('app.media.ex_shoulder_reverse_fly_card'), start: $r('app.media.ex_shoulder_reverse_fly_start'), end: $r('app.media.ex_shoulder_reverse_fly_end') },
  { id: 'shoulder_face_pull', card: $r('app.media.ex_shoulder_face_pull_card'), start: $r('app.media.ex_shoulder_face_pull_start'), end: $r('app.media.ex_shoulder_face_pull_end') },
  { id: 'shoulder_seated_bb_press', card: $r('app.media.ex_shoulder_seated_bb_press_card'), start: $r('app.media.ex_shoulder_seated_bb_press_start'), end: $r('app.media.ex_shoulder_seated_bb_press_end') },
  { id: 'shoulder_arnold', card: $r('app.media.ex_shoulder_arnold_card'), start: $r('app.media.ex_shoulder_arnold_start'), end: $r('app.media.ex_shoulder_arnold_end') },
  { id: 'shoulder_machine_press', card: $r('app.media.ex_shoulder_machine_press_card'), start: $r('app.media.ex_shoulder_machine_press_start'), end: $r('app.media.ex_shoulder_machine_press_end') },
  { id: 'shoulder_cable_lateral', card: $r('app.media.ex_shoulder_cable_lateral_card'), start: $r('app.media.ex_shoulder_cable_lateral_start'), end: $r('app.media.ex_shoulder_cable_lateral_end') },
  { id: 'shoulder_cable_rear_fly', card: $r('app.media.ex_shoulder_cable_rear_fly_card'), start: $r('app.media.ex_shoulder_cable_rear_fly_start'), end: $r('app.media.ex_shoulder_cable_rear_fly_end') },
  { id: 'shoulder_machine_reverse_fly', card: $r('app.media.ex_shoulder_machine_reverse_fly_card'), start: $r('app.media.ex_shoulder_machine_reverse_fly_start'), end: $r('app.media.ex_shoulder_machine_reverse_fly_end') },
  { id: 'shoulder_bent_over_raise', card: $r('app.media.ex_shoulder_bent_over_raise_card'), start: $r('app.media.ex_shoulder_bent_over_raise_start'), end: $r('app.media.ex_shoulder_bent_over_raise_end') },
  { id: 'shoulder_cable_front', card: $r('app.media.ex_shoulder_cable_front_card'), start: $r('app.media.ex_shoulder_cable_front_start'), end: $r('app.media.ex_shoulder_cable_front_end') },
  { id: 'back_pullup', card: $r('app.media.ex_back_pullup_card'), start: $r('app.media.ex_back_pullup_start'), end: $r('app.media.ex_back_pullup_end') },
  { id: 'back_lat_pulldown', card: $r('app.media.ex_back_lat_pulldown_card'), start: $r('app.media.ex_back_lat_pulldown_start'), end: $r('app.media.ex_back_lat_pulldown_end') },
  { id: 'back_bb_row', card: $r('app.media.ex_back_bb_row_card'), start: $r('app.media.ex_back_bb_row_start'), end: $r('app.media.ex_back_bb_row_end') },
  { id: 'back_db_row', card: $r('app.media.ex_back_db_row_card'), start: $r('app.media.ex_back_db_row_start'), end: $r('app.media.ex_back_db_row_end') },
  { id: 'back_seated_row', card: $r('app.media.ex_back_seated_row_card'), start: $r('app.media.ex_back_seated_row_start'), end: $r('app.media.ex_back_seated_row_end') },
  { id: 'back_deadlift', card: $r('app.media.ex_back_deadlift_card'), start: $r('app.media.ex_back_deadlift_start'), end: $r('app.media.ex_back_deadlift_end') },
  { id: 'back_chinup', card: $r('app.media.ex_back_chinup_card'), start: $r('app.media.ex_back_chinup_start'), end: $r('app.media.ex_back_chinup_end') },
  { id: 'back_wide_pulldown', card: $r('app.media.ex_back_wide_pulldown_card'), start: $r('app.media.ex_back_wide_pulldown_start'), end: $r('app.media.ex_back_wide_pulldown_end') },
  { id: 'back_close_pulldown', card: $r('app.media.ex_back_close_pulldown_card'), start: $r('app.media.ex_back_close_pulldown_start'), end: $r('app.media.ex_back_close_pulldown_end') },
  { id: 'back_reverse_pulldown', card: $r('app.media.ex_back_reverse_pulldown_card'), start: $r('app.media.ex_back_reverse_pulldown_start'), end: $r('app.media.ex_back_reverse_pulldown_end') },
  { id: 'back_chest_supported_row', card: $r('app.media.ex_back_chest_supported_row_card'), start: $r('app.media.ex_back_chest_supported_row_start'), end: $r('app.media.ex_back_chest_supported_row_end') },
  { id: 'back_straight_arm_pulldown', card: $r('app.media.ex_back_straight_arm_pulldown_card'), start: $r('app.media.ex_back_straight_arm_pulldown_start'), end: $r('app.media.ex_back_straight_arm_pulldown_end') },
  { id: 'back_hyperextension', card: $r('app.media.ex_back_hyperextension_card'), start: $r('app.media.ex_back_hyperextension_start'), end: $r('app.media.ex_back_hyperextension_end') },
  { id: 'back_tbar_row', card: $r('app.media.ex_back_tbar_row_card'), start: $r('app.media.ex_back_tbar_row_start'), end: $r('app.media.ex_back_tbar_row_end') },
  { id: 'back_inverted_row', card: $r('app.media.ex_back_inverted_row_card'), start: $r('app.media.ex_back_inverted_row_start'), end: $r('app.media.ex_back_inverted_row_end') },
  { id: 'back_one_arm_cable_row', card: $r('app.media.ex_back_one_arm_cable_row_card'), start: $r('app.media.ex_back_one_arm_cable_row_start'), end: $r('app.media.ex_back_one_arm_cable_row_end') },
  { id: 'arm_bb_curl', card: $r('app.media.ex_arm_bb_curl_card'), start: $r('app.media.ex_arm_bb_curl_start'), end: $r('app.media.ex_arm_bb_curl_end') },
  { id: 'arm_db_curl', card: $r('app.media.ex_arm_db_curl_card'), start: $r('app.media.ex_arm_db_curl_start'), end: $r('app.media.ex_arm_db_curl_end') },
  { id: 'arm_hammer_curl', card: $r('app.media.ex_arm_hammer_curl_card'), start: $r('app.media.ex_arm_hammer_curl_start'), end: $r('app.media.ex_arm_hammer_curl_end') },
  { id: 'arm_pushdown', card: $r('app.media.ex_arm_pushdown_card'), start: $r('app.media.ex_arm_pushdown_start'), end: $r('app.media.ex_arm_pushdown_end') },
  { id: 'arm_skull_crusher', card: $r('app.media.ex_arm_skull_crusher_card'), start: $r('app.media.ex_arm_skull_crusher_start'), end: $r('app.media.ex_arm_skull_crusher_end') },
  { id: 'arm_incline_curl', card: $r('app.media.ex_arm_incline_curl_card'), start: $r('app.media.ex_arm_incline_curl_start'), end: $r('app.media.ex_arm_incline_curl_end') },
  { id: 'arm_preacher_curl', card: $r('app.media.ex_arm_preacher_curl_card'), start: $r('app.media.ex_arm_preacher_curl_start'), end: $r('app.media.ex_arm_preacher_curl_end') },
  { id: 'arm_cable_curl', card: $r('app.media.ex_arm_cable_curl_card'), start: $r('app.media.ex_arm_cable_curl_start'), end: $r('app.media.ex_arm_cable_curl_end') },
  { id: 'arm_concentration_curl', card: $r('app.media.ex_arm_concentration_curl_card'), start: $r('app.media.ex_arm_concentration_curl_start'), end: $r('app.media.ex_arm_concentration_curl_end') },
  { id: 'arm_overhead_extension', card: $r('app.media.ex_arm_overhead_extension_card'), start: $r('app.media.ex_arm_overhead_extension_start'), end: $r('app.media.ex_arm_overhead_extension_end') },
  { id: 'arm_one_arm_pushdown', card: $r('app.media.ex_arm_one_arm_pushdown_card'), start: $r('app.media.ex_arm_one_arm_pushdown_start'), end: $r('app.media.ex_arm_one_arm_pushdown_end') },
  { id: 'arm_kickback', card: $r('app.media.ex_arm_kickback_card'), start: $r('app.media.ex_arm_kickback_start'), end: $r('app.media.ex_arm_kickback_end') },
  { id: 'arm_wrist_curl', card: $r('app.media.ex_arm_wrist_curl_card'), start: $r('app.media.ex_arm_wrist_curl_start'), end: $r('app.media.ex_arm_wrist_curl_end') },
  { id: 'arm_reverse_wrist', card: $r('app.media.ex_arm_reverse_wrist_card'), start: $r('app.media.ex_arm_reverse_wrist_start'), end: $r('app.media.ex_arm_reverse_wrist_end') },
  { id: 'arm_ez_curl', card: $r('app.media.ex_arm_ez_curl_card'), start: $r('app.media.ex_arm_ez_curl_start'), end: $r('app.media.ex_arm_ez_curl_end') },
  { id: 'arm_close_grip_bench', card: $r('app.media.ex_arm_close_grip_bench_card'), start: $r('app.media.ex_arm_close_grip_bench_start'), end: $r('app.media.ex_arm_close_grip_bench_end') },
  { id: 'glute_hip_thrust', card: $r('app.media.ex_glute_hip_thrust_card'), start: $r('app.media.ex_glute_hip_thrust_start'), end: $r('app.media.ex_glute_hip_thrust_end') },
  { id: 'glute_rdl', card: $r('app.media.ex_glute_rdl_card'), start: $r('app.media.ex_glute_rdl_start'), end: $r('app.media.ex_glute_rdl_end') },
  { id: 'glute_bridge', card: $r('app.media.ex_glute_bridge_card'), start: $r('app.media.ex_glute_bridge_start'), end: $r('app.media.ex_glute_bridge_end') },
  { id: 'glute_abduction', card: $r('app.media.ex_glute_abduction_card'), start: $r('app.media.ex_glute_abduction_start'), end: $r('app.media.ex_glute_abduction_end') },
  { id: 'glute_single_leg_thrust', card: $r('app.media.ex_glute_single_leg_thrust_card'), start: $r('app.media.ex_glute_single_leg_thrust_start'), end: $r('app.media.ex_glute_single_leg_thrust_end') },
  { id: 'glute_single_leg_bridge', card: $r('app.media.ex_glute_single_leg_bridge_card'), start: $r('app.media.ex_glute_single_leg_bridge_start'), end: $r('app.media.ex_glute_single_leg_bridge_end') },
  { id: 'glute_cable_kickback', card: $r('app.media.ex_glute_cable_kickback_card'), start: $r('app.media.ex_glute_cable_kickback_start'), end: $r('app.media.ex_glute_cable_kickback_end') },
  { id: 'glute_donkey_kick', card: $r('app.media.ex_glute_donkey_kick_card'), start: $r('app.media.ex_glute_donkey_kick_start'), end: $r('app.media.ex_glute_donkey_kick_end') },
  { id: 'glute_side_lying_abduction', card: $r('app.media.ex_glute_side_lying_abduction_card'), start: $r('app.media.ex_glute_side_lying_abduction_start'), end: $r('app.media.ex_glute_side_lying_abduction_end') },
  { id: 'glute_band_lateral_walk', card: $r('app.media.ex_glute_band_lateral_walk_card'), start: $r('app.media.ex_glute_band_lateral_walk_start'), end: $r('app.media.ex_glute_band_lateral_walk_end') },
  { id: 'glute_clamshell', card: $r('app.media.ex_glute_clamshell_card'), start: $r('app.media.ex_glute_clamshell_start'), end: $r('app.media.ex_glute_clamshell_end') },
  { id: 'glute_pull_through', card: $r('app.media.ex_glute_pull_through_card'), start: $r('app.media.ex_glute_pull_through_start'), end: $r('app.media.ex_glute_pull_through_end') },
  { id: 'glute_frog_pump', card: $r('app.media.ex_glute_frog_pump_card'), start: $r('app.media.ex_glute_frog_pump_start'), end: $r('app.media.ex_glute_frog_pump_end') },
  { id: 'leg_squat', card: $r('app.media.ex_leg_squat_card'), start: $r('app.media.ex_leg_squat_start'), end: $r('app.media.ex_leg_squat_end') },
  { id: 'leg_press', card: $r('app.media.ex_leg_press_card'), start: $r('app.media.ex_leg_press_start'), end: $r('app.media.ex_leg_press_end') },
  { id: 'leg_extension', card: $r('app.media.ex_leg_extension_card'), start: $r('app.media.ex_leg_extension_start'), end: $r('app.media.ex_leg_extension_end') },
  { id: 'leg_curl', card: $r('app.media.ex_leg_curl_card'), start: $r('app.media.ex_leg_curl_start'), end: $r('app.media.ex_leg_curl_end') },
  { id: 'leg_lunge', card: $r('app.media.ex_leg_lunge_card'), start: $r('app.media.ex_leg_lunge_start'), end: $r('app.media.ex_leg_lunge_end') },
  { id: 'leg_calf_raise', card: $r('app.media.ex_leg_calf_raise_card'), start: $r('app.media.ex_leg_calf_raise_start'), end: $r('app.media.ex_leg_calf_raise_end') },
  { id: 'leg_front_squat', card: $r('app.media.ex_leg_front_squat_card'), start: $r('app.media.ex_leg_front_squat_start'), end: $r('app.media.ex_leg_front_squat_end') },
  { id: 'leg_goblet_squat', card: $r('app.media.ex_leg_goblet_squat_card'), start: $r('app.media.ex_leg_goblet_squat_start'), end: $r('app.media.ex_leg_goblet_squat_end') },
  { id: 'leg_split_squat', card: $r('app.media.ex_leg_split_squat_card'), start: $r('app.media.ex_leg_split_squat_start'), end: $r('app.media.ex_leg_split_squat_end') },
  { id: 'leg_bulgarian_split', card: $r('app.media.ex_leg_bulgarian_split_card'), start: $r('app.media.ex_leg_bulgarian_split_start'), end: $r('app.media.ex_leg_bulgarian_split_end') },
  { id: 'leg_step_up', card: $r('app.media.ex_leg_step_up_card'), start: $r('app.media.ex_leg_step_up_start'), end: $r('app.media.ex_leg_step_up_end') },
  { id: 'leg_hack_squat', card: $r('app.media.ex_leg_hack_squat_card'), start: $r('app.media.ex_leg_hack_squat_start'), end: $r('app.media.ex_leg_hack_squat_end') },
  { id: 'leg_seated_curl', card: $r('app.media.ex_leg_seated_curl_card'), start: $r('app.media.ex_leg_seated_curl_start'), end: $r('app.media.ex_leg_seated_curl_end') },
  { id: 'leg_standing_calf', card: $r('app.media.ex_leg_standing_calf_card'), start: $r('app.media.ex_leg_standing_calf_start'), end: $r('app.media.ex_leg_standing_calf_end') },
  { id: 'leg_seated_calf', card: $r('app.media.ex_leg_seated_calf_card'), start: $r('app.media.ex_leg_seated_calf_start'), end: $r('app.media.ex_leg_seated_calf_end') },
  { id: 'leg_walking_lunge', card: $r('app.media.ex_leg_walking_lunge_card'), start: $r('app.media.ex_leg_walking_lunge_start'), end: $r('app.media.ex_leg_walking_lunge_end') },
  { id: 'leg_reverse_lunge', card: $r('app.media.ex_leg_reverse_lunge_card'), start: $r('app.media.ex_leg_reverse_lunge_start'), end: $r('app.media.ex_leg_reverse_lunge_end') },
  { id: 'leg_sumo_squat', card: $r('app.media.ex_leg_sumo_squat_card'), start: $r('app.media.ex_leg_sumo_squat_start'), end: $r('app.media.ex_leg_sumo_squat_end') },
  { id: 'abs_crunch', card: $r('app.media.ex_abs_crunch_card'), start: $r('app.media.ex_abs_crunch_start'), end: $r('app.media.ex_abs_crunch_end') },
  { id: 'abs_reverse_crunch', card: $r('app.media.ex_abs_reverse_crunch_card'), start: $r('app.media.ex_abs_reverse_crunch_start'), end: $r('app.media.ex_abs_reverse_crunch_end') },
  { id: 'abs_leg_raise', card: $r('app.media.ex_abs_leg_raise_card'), start: $r('app.media.ex_abs_leg_raise_start'), end: $r('app.media.ex_abs_leg_raise_end') },
  { id: 'abs_machine_crunch', card: $r('app.media.ex_abs_machine_crunch_card'), start: $r('app.media.ex_abs_machine_crunch_start'), end: $r('app.media.ex_abs_machine_crunch_end') },
  { id: 'abs_cable_crunch', card: $r('app.media.ex_abs_cable_crunch_card'), start: $r('app.media.ex_abs_cable_crunch_start'), end: $r('app.media.ex_abs_cable_crunch_end') },
  { id: 'abs_hanging_knee', card: $r('app.media.ex_abs_hanging_knee_card'), start: $r('app.media.ex_abs_hanging_knee_start'), end: $r('app.media.ex_abs_hanging_knee_end') },
  { id: 'abs_hanging_leg', card: $r('app.media.ex_abs_hanging_leg_card'), start: $r('app.media.ex_abs_hanging_leg_start'), end: $r('app.media.ex_abs_hanging_leg_end') },
  { id: 'abs_alt_crunch', card: $r('app.media.ex_abs_alt_crunch_card'), start: $r('app.media.ex_abs_alt_crunch_start'), end: $r('app.media.ex_abs_alt_crunch_end') },
  { id: 'abs_heel_touch', card: $r('app.media.ex_abs_heel_touch_card'), start: $r('app.media.ex_abs_heel_touch_start'), end: $r('app.media.ex_abs_heel_touch_end') },
  { id: 'abs_flutter_kick', card: $r('app.media.ex_abs_flutter_kick_card'), start: $r('app.media.ex_abs_flutter_kick_start'), end: $r('app.media.ex_abs_flutter_kick_end') },
  { id: 'abs_decline_crunch', card: $r('app.media.ex_abs_decline_crunch_card'), start: $r('app.media.ex_abs_decline_crunch_start'), end: $r('app.media.ex_abs_decline_crunch_end') },
  { id: 'abs_v_up', card: $r('app.media.ex_abs_v_up_card'), start: $r('app.media.ex_abs_v_up_start'), end: $r('app.media.ex_abs_v_up_end') },
  { id: 'core_dead_bug', card: $r('app.media.ex_core_dead_bug_card'), start: $r('app.media.ex_core_dead_bug_start'), end: $r('app.media.ex_core_dead_bug_end') },
  { id: 'core_bird_dog', card: $r('app.media.ex_core_bird_dog_card'), start: $r('app.media.ex_core_bird_dog_start'), end: $r('app.media.ex_core_bird_dog_end') },
  { id: 'core_shoulder_tap', card: $r('app.media.ex_core_shoulder_tap_card'), start: $r('app.media.ex_core_shoulder_tap_start'), end: $r('app.media.ex_core_shoulder_tap_end') },
  { id: 'core_pallof', card: $r('app.media.ex_core_pallof_card'), start: $r('app.media.ex_core_pallof_start'), end: $r('app.media.ex_core_pallof_end') },
  { id: 'core_side_plank_hip', card: $r('app.media.ex_core_side_plank_hip_card'), start: $r('app.media.ex_core_side_plank_hip_start'), end: $r('app.media.ex_core_side_plank_hip_end') },
  { id: 'core_up_down', card: $r('app.media.ex_core_up_down_card'), start: $r('app.media.ex_core_up_down_start'), end: $r('app.media.ex_core_up_down_end') },
  { id: 'core_russian_twist', card: $r('app.media.ex_core_russian_twist_card'), start: $r('app.media.ex_core_russian_twist_start'), end: $r('app.media.ex_core_russian_twist_end') },
  { id: 'core_woodchop', card: $r('app.media.ex_core_woodchop_card'), start: $r('app.media.ex_core_woodchop_start'), end: $r('app.media.ex_core_woodchop_end') },
  { id: 'core_hollow_rock', card: $r('app.media.ex_core_hollow_rock_card'), start: $r('app.media.ex_core_hollow_rock_start'), end: $r('app.media.ex_core_hollow_rock_end') },
  { id: 'core_body_saw', card: $r('app.media.ex_core_body_saw_card'), start: $r('app.media.ex_core_body_saw_start'), end: $r('app.media.ex_core_body_saw_end') },
  { id: 'cardio_jump_rope', card: $r('app.media.ex_cardio_jump_rope_card'), start: $r('app.media.ex_cardio_jump_rope_start'), end: $r('app.media.ex_cardio_jump_rope_end') },
  { id: 'cardio_jumping_jack', card: $r('app.media.ex_cardio_jumping_jack_card'), start: $r('app.media.ex_cardio_jumping_jack_start'), end: $r('app.media.ex_cardio_jumping_jack_end') },
  { id: 'cardio_mountain_climber', card: $r('app.media.ex_cardio_mountain_climber_card'), start: $r('app.media.ex_cardio_mountain_climber_start'), end: $r('app.media.ex_cardio_mountain_climber_end') },
  { id: 'cardio_burpee', card: $r('app.media.ex_cardio_burpee_card'), start: $r('app.media.ex_cardio_burpee_start'), end: $r('app.media.ex_cardio_burpee_end') }
];

export function artworkOf(exerciseId: string): ExerciseArtwork | null {
  for (let i = 0; i < EXERCISE_ARTWORK.length; i++) {
    if (EXERCISE_ARTWORK[i].id === exerciseId) {
      return EXERCISE_ARTWORK[i];
    }
  }
  return null;
}

export function cardImageOf(exerciseId: string, partKey: PartKey): Resource {
  const art: ExerciseArtwork | null = artworkOf(exerciseId);
  if (art !== null) {
    return art.card;
  }
  return partFallback(partKey);
}

export function partFallback(partKey: PartKey): Resource {
  if (partKey === 'shoulder') {
    return $r('app.media.part_shoulder');
  }
  if (partKey === 'back') {
    return $r('app.media.part_back');
  }
  if (partKey === 'arm') {
    return $r('app.media.part_arm');
  }
  if (partKey === 'glute') {
    return $r('app.media.part_glute');
  }
  if (partKey === 'leg') {
    return $r('app.media.part_leg');
  }
  if (partKey === 'abs') {
    return $r('app.media.part_abs');
  }
  if (partKey === 'core') {
    return $r('app.media.part_core');
  }
  if (partKey === 'cardio') {
    return $r('app.media.part_cardio');
  }
  return $r('app.media.part_chest');
}
