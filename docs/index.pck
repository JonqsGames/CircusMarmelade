GDPC                p                                                                         T   res://.godot/exported/133200997/export-38ac771870673db8cfcbb0a8bc96a1ba-spawner.scn  ?      �      Z���ڴ(��f�Xy�    P   res://.godot/exported/133200997/export-609f762188a68253d349ec58c4f3a8d3-game.scn�Z      F      $z�5� �S���-��    X   res://.godot/exported/133200997/export-d1ef8fc1c8d8fa2f03d8205403f4d680-character.scn   `      *      'H��@�	���    ,   res://.godot/global_script_class_cache.cfg  @y      �       �>����w����,��    H   res://.godot/imported/clown.png-a53cbe3fda904697a03707009ae85dcd.ctex   0J      �      �7{����3���]�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex�e            ：Qt�E�cO���       res://.godot/uid_cache.bin  �}      �       4Y�*���P�v&��       res://DebugContainer.gd `u      �      �ܽ��GB8^��<:S1       res://Plank.gd  �s      t      ���D�j����Y;�&�       res://entities/Character.gd         V      S��;�CGȗC�剕       res://entities/Spawner.gd   p=      �      U�;	���:Uz�O=�6    $   res://entities/character.tscn.remap �w      f       ���|�➶Qb�rd<�    $   res://entities/spawner.tscn.remap   `x      d       �/���N9��_�cQA       res://game.tscn.remap   �x      a       �?��� �ު��y�    (   res://globals/action_press_manager.gd   �E      8      ����r�@��΋K�h       res://icon.svg  �y      �      k����X3Y���f       res://icon.svg.import   s      �       1T���s|����f.�       res://img/clown.png.import  �Y      �       �#��=���/ �        res://project.binary@~      �
      �Mb��a��CER~        extends CharacterBody2D
enum Status {
	PREPARING,
	STABLE,
	PRESSING,
	AERIAL,
	PILED,
	CRASHED,
	BASE,
	HOLDING
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var status = Status.PREPARING :
	set(value):
		status = value
		print("Character change status to %s" % Status.keys()[status])
		if status == Status.CRASHED:
			self.rotation = 0.0
@export var left_side = false

var relative_stick_position = Vector3.ZERO
@onready var plank : Plank = $"/root/Game/Balance/Plank"

var move_speed = 256.0
var rotate_speed = 7.0

signal dead()

func get_relative_d():
	var x = relative_stick_position.x
	if left_side:
		x = -x
	return x

func _on_pressing_done():
	if self.status == Status.PRESSING:
		self.status = Status.STABLE
		plank.release.connect(self._on_tilt_done,CONNECT_ONE_SHOT)

func _on_tilt_done():
	self.status = Status.AERIAL
	self.velocity.y = -ActionPressManager.get_boost_value() * get_relative_d()/plank.get_half_size()
	ActionPressManager.boost()
func _ready():
	if left_side:
		$Sprite2D.flip_h = true
func _process(delta):
	# DEBUG
	$DebugR.text = "R %.2f" % [self.rotation]

func _physics_process(delta):
	# Add the gravity.
	$AnimationTree.set("parameters/BlendWalk/blend_position", float(abs(velocity.x) > 0.0))
	var v = move_speed * delta
	var r = rotate_speed * delta
	match status:
		Status.PREPARING:
			if Input.is_action_pressed("left"):
				self.velocity.x -= v
			if Input.is_action_pressed("right"):
				self.velocity.x += v
			move_and_slide()
			if abs(position.x) > 64.0:
				self.velocity.x = -sign(self.global_position.x) * 200.0
				ActionPressManager.action_peak_height = abs(self.global_position.y) * get_relative_d()/plank.get_half_size()
				self.status = Status.AERIAL
		Status.AERIAL:
			if Input.is_action_pressed("left"):
				self.velocity.x -= v
			if Input.is_action_pressed("right"):
				self.velocity.x += v
			var pr = $RotationCenter.global_position
			if Input.is_action_pressed("rotate_positive"):
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(r)
				self.rotate(r)
				#self.position.x -= sin(r) * $RotationCenter.position.y
				#self.position.y -= cos(r) * $RotationCenter.position.y
			elif Input.is_action_pressed("rotate_negative"):
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(-r)
				self.rotate(-r)
				#self.position.x += sin(r) * $RotationCenter.position.y
				#self.position.y += cos(r) * $RotationCenter.position.y
			else:
				# Lerp to stable
				self.rotation = lerp_angle(self.rotation,0.0,delta * 0.6)
			pr = $RotationCenter.global_position - pr
			self.global_position += -pr
			var accel_grav = gravity * delta
			if velocity.y < 0.0 and velocity.y > -accel_grav:
				# Reach peak
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				print("Character reach peak at %s" % [ActionPressManager.action_peak_height])
			velocity.y += accel_grav
			if move_and_slide():
				for i in range(self.get_slide_collision_count()):
					var col : KinematicCollision2D = get_slide_collision(i)
					var c : Node2D = col.get_collider()
					var is_falling = velocity.y >= 0.0
					if is_falling:
						if c.is_in_group("Character"):
							if (c.status == Status.PILED or c.status == Status.BASE) and col.get_local_shape().name == "FeetShape":
								self.status = Status.PILED
								c.status = Status.HOLDING
								self.reparent(c)
								dead.emit()
								break
							else:
								self.status = Status.CRASHED
								self.reparent(c)
								dead.emit()
								break
						elif c is Plank:
							# check relative x position
							#plank = c
							relative_stick_position = plank.to_local(self.global_position)
							var x = get_relative_d()
							if x > 0 and col.get_local_shape().name == "FeetShape":
								self.status = Status.PRESSING
								self.velocity = Vector2.ZERO
								plank.release.connect(self._on_pressing_done,CONNECT_ONE_SHOT | CONNECT_DEFERRED)
								#Rotate
								c.tilt(left_side)
								break
							else:
								status = Status.CRASHED
								self.reparent(c)
								dead.emit()
								break
						elif c.name == "Board" and col.get_local_shape().name == "FeetShape":
							self.status = Status.PREPARING
							self.rotation = 0.0
							self.velocity = Vector2.ZERO
							break
						else:
							status = Status.CRASHED
							self.reparent(c)
							dead.emit()
							break
		Status.STABLE, Status.PRESSING:
			self.rotation = lerp_angle(self.rotation,0.0,delta * 1.5)
			self.global_position = plank.to_global(relative_stick_position)
		Status.PILED:
			self.position = lerp(self.position,Vector2(0.0,-40.0),delta * 2.0)
			self.rotate((randf() - 0.5) * delta * 0.4)
			self.rotation = lerp_angle(self.rotation,0.0,delta * 1.0)
	
func die():
	self.queue_free()
          RSRC                    PackedScene            ��������                                            Q   	   Sprite2D    frame    .    ..    AnimationPlayer    resource_local_to_scene    resource_name    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    radius    height    radial_segments    rings    script    custom_solver_bias    length 
   loop_mode    step    tracks/0/type    tracks/0/imported    tracks/0/enabled    tracks/0/path    tracks/0/interp    tracks/0/loop_wrap    tracks/0/keys    tracks/1/type    tracks/1/imported    tracks/1/enabled    tracks/1/path    tracks/1/interp    tracks/1/loop_wrap    tracks/1/keys    _data 
   animation 
   play_mode    blend_point_0/node    blend_point_0/pos    blend_point_1/node    blend_point_1/pos    blend_point_2/node    blend_point_2/pos 
   min_space 
   max_space    snap    value_label    blend_mode    sync    xfade_time    xfade_curve    reset 	   priority    switch_mode    advance_mode    advance_condition    advance_expression    state_machine_type    allow_transition_to_self    reset_ends    states/BlendWalk/node    states/BlendWalk/position    states/End/node    states/End/position    states/Start/node    states/Start/position    states/crash/node    states/crash/position    states/flying/node    states/flying/position    states/landing/node    states/landing/position    states/piled/node    states/piled/position    states/piling/node    states/piling/position    transitions    graph_offset 	   _bundled       Script    res://entities/Character.gd ��������
   Texture2D    res://img/clown.png �Ig�(Kw#      local://CapsuleMesh_mrfxx 1         local://CapsuleShape2D_taav1 e         local://CircleShape2D_c0d3n �         local://Animation_13r30 �         local://Animation_2rjii �         local://Animation_0wym0 �         local://Animation_34tyd �         local://Animation_oec6f �         local://Animation_txy0v �         local://Animation_nhaw8 �         local://Animation_p4efs          local://Animation_so3vp 5         local://Animation_xn8bf P         local://AnimationLibrary_cictl u      %   local://AnimationNodeAnimation_4hseg �      %   local://AnimationNodeAnimation_2vxlo �      %   local://AnimationNodeAnimation_hyywk       (   local://AnimationNodeBlendSpace1D_cqpov X      %   local://AnimationNodeAnimation_tyscs �      %   local://AnimationNodeAnimation_nnuin       %   local://AnimationNodeAnimation_efsq3 U      %   local://AnimationNodeAnimation_wl6ln �      %   local://AnimationNodeAnimation_kv5n6 �      2   local://AnimationNodeStateMachineTransition_6eq2t       2   local://AnimationNodeStateMachineTransition_nux3y s      2   local://AnimationNodeStateMachineTransition_o5ci4 �      2   local://AnimationNodeStateMachineTransition_ubq81 F      2   local://AnimationNodeStateMachineTransition_duvba �      2   local://AnimationNodeStateMachineTransition_axfp4 �      2   local://AnimationNodeStateMachineTransition_vhirm C      2   local://AnimationNodeStateMachineTransition_1lonl �      2   local://AnimationNodeStateMachineTransition_a8uea �      2   local://AnimationNodeStateMachineTransition_j17hc N       (   local://AnimationNodeStateMachine_ww7wi �          local://PackedScene_7if2h �#         CapsuleMesh            �A        �B         CapsuleShape2D            `A         B         CircleShape2D            @A      
   Animation 	         o�:         value                                                                    times !                transitions !        �?      values                    update             
   Animation             crash       A�?         value                                                                    times !          ��L>      transitions !        �?  �?      values                         update                 method                                 !         "         #               times !      ��?      transitions !        �?      values                   method ,      die       args              
   Animation 
            fail       l�L>         value                                                                    times !          ��L>      transitions !        �?  �?      values                         update             
   Animation 
            flying       ���>         value                                                                    times !          ���>      transitions !        �?  �?      values                
         update              
   Animation 
            idle                   value                                                                    times !                transitions !        �?      values                    update             
   Animation 	         
   idle_walk          value                                                                    times !                transitions !        �?      values                   update             
   Animation 
            landing       ���>         value                                                                    times !          ���>      transitions !        �?  �?      values                	         update              
   Animation 
            piled       隙>         value                                                                    times !          ���>      transitions !        �?  �?      values                         update              
   Animation 
            piling       ���>         value                                                                    times !          ���>      transitions !        �?  �?      values                         update              
   Animation             walk       ��>                  value                                                                    times !          ���>      transitions !        �?  �?      values                         update                 AnimationLibrary    $      
         RESET                crash                fail                flying                idle             
   idle_walk                landing       	         piled       
         piling                walk                   AnimationNodeAnimation    %   ,      walk          AnimationNodeAnimation    %   ,      walk          AnimationNodeAnimation    %   ,   
   idle_walk          AnimationNodeBlendSpace1D    '            (        ��)            *        �?+            ,          -                   AnimationNodeAnimation    %   ,      crash          AnimationNodeAnimation    %   ,      flying          AnimationNodeAnimation    %   ,      landing          AnimationNodeAnimation    %   ,      piled          AnimationNodeAnimation    %   ,      piling       $   AnimationNodeStateMachineTransition    7         8         :         status == Status.STABLE       $   AnimationNodeStateMachineTransition    7         8         :         status == Status.AERIAL       $   AnimationNodeStateMachineTransition    8         :         status == Status.PILED       $   AnimationNodeStateMachineTransition    8         :         status == Status.CRASHED       $   AnimationNodeStateMachineTransition    7         8               $   AnimationNodeStateMachineTransition    7         8               $   AnimationNodeStateMachineTransition    8               $   AnimationNodeStateMachineTransition    8         :         status == Status.AERIAL       $   AnimationNodeStateMachineTransition    8         :         status == Status.PREPARING       $   AnimationNodeStateMachineTransition    8         :         status == Status.BASE          AnimationNodeStateMachine    >            ?   
     xC  �B@      A   
    @aD  �BB      C   
     �B  �BD            E   
    @-D  CF            G   
    ��C  �BH            I   
    �D  �BJ            K   
    @#D  VCL            M   
     �C  eCN               flying       landing                landing       flying                flying       piling                flying       crash                crash       End                piling       piled                Start    
   BlendWalk             
   BlendWalk       flying                flying    
   BlendWalk             
   BlendWalk       piling                    PackedScene    P      	         names "   %   
   Character 	   position    script    CharacterBody2D    Mesh    visible 	   modulate    mesh    MeshInstance2D 	   Sprite2D    texture_filter    texture_repeat    scale    texture    hframes    vframes 
   BodyShape    shape    CollisionShape2D 
   FeetShape    RotationCenter 	   Marker2D    DebugR    offset_left    offset_top    offset_right    offset_bottom    text    horizontal_alignment    Label    AnimationPlayer 
   libraries    AnimationTree 
   tree_root    advance_expression_base_node    anim_player $   parameters/BlendWalk/blend_position    	   variants       
         �?                    ��,?    ��Z>  �?
         �                
     �?  ��
      @   @                     
     �?  ��         
         P�         
          �     ��     L�     �A     ��      00                             !                        )   ףp=
��      node_count    	         nodes     |   ��������       ����                                     ����                                       	   	   ����   
                           	      
                           ����                                 ����                                 ����                           ����                                                               ����                             ����   !      "      #      $                conn_count              conns               node_paths              editable_instances              version             RSRC    extends Node2D
const CHARACTER = preload("res://entities/character.tscn")

@export var left_side = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if left_side:
		for c in self.get_children():
			c.position.x = -c.position.x
	self.spawn()

func spawn():
	var c = CHARACTER.instantiate()
	c.left_side = left_side
	$SpawnPoint.add_child(c)
	c.dead.connect(self.spawn,CONNECT_ONE_SHOT)
         RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    custom_solver_bias    size    script    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    subdivide_width    subdivide_height    subdivide_depth 	   _bundled       Script    res://entities/Spawner.gd ��������      local://RectangleShape2D_paxhl g         local://BoxMesh_mii6f �         local://RectangleShape2D_fqorq �         local://BoxMesh_x1ays �         local://PackedScene_x2s4s !         RectangleShape2D       
      B  HC         BoxMesh             B  HC  �?         RectangleShape2D       
      C   A         BoxMesh             C   A  �?         PackedScene          	         names "         Spawner 	   position    script 
   left_side    Node2D    Pole    StaticBody2D    CollisionShape2D    shape    Mesh 	   modulate    mesh    MeshInstance2D    SpawnPoint 	   Marker2D    Board    	   variants       
     fC                    
         ��             wK">���>"�?>  �?         
     ��  *�
     ��  #�                        node_count             nodes     N   ��������       ����                                        ����                          ����                       	   ����   
                              ����                           ����                          ����      	                 	   ����      
             conn_count              conns               node_paths              editable_instances              version             RSRC              extends Node

const MIN_ACTION_DELAY = 1.0
const ACTION_TIME_WINDOW = 0.8

var last_time_action_pressed = 0

var action_peak_height = 0.0

signal boost_proceed()

func get_elapsed_time_last_action():
	return Time.get_unix_time_from_system() - last_time_action_pressed

func boost():
	boost_proceed.emit()
	last_time_action_pressed = 0.0

func get_boost_value():
	return clamp(action_peak_height,256.0,350.0) * (2.0 + get_boost_multiplicator() * 0.8)
	
func get_boost_multiplicator():
	var v = 0.0
	# Evaluate based on latest action the amount of boost the character will get
	# Will return value between 1.0 for perject jump and 0.0 for failed jump
	var dt = get_elapsed_time_last_action() / ACTION_TIME_WINDOW
	if dt >= 0.0 and dt <= 1.0:
		# out of defined window
		v = 1.0 - dt
	return v
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("action") and get_elapsed_time_last_action() > MIN_ACTION_DELAY:
		last_time_action_pressed = Time.get_unix_time_from_system()
		print("Action registered")
        GST2            ����                        `  RIFFX  WEBPVP8LL  /���g`����eiN�T�4���38���x�3Ӷ������E����������{�0��G�9�n�s: !������c�!�>E�
No�����/�M����]�Xu�D���I Q�~+I9K�22�+���%I�$I�-Tw��7����y�{������f������?c
���'M��zn9���}�g���{���-~n6xnj�Gd�����FM-�+���7@U����Ejom�`�K�uqs�ro��7��,כ��&O�M�i���Y���~{0mR��܏�7�Tn�C�h����ޤ9�#�i�}w�1�������f�FT\-l��ݝg����q���������#�}����q���-��7ں]�5��]:��~��D���>�17�wޥ�1�)=�{��5�J�7ǳ��5�y��t5�g�'{���l�8�l�jW��[�������Ru%\���q�-R�=��k5�͍`���] u�5w�Ԁps�0�n�tdY�IF���@�-��S�3��^c"�)�ajK��z)T2��V��� �J}�dʍ�dH-r��.�9����o�(������f�����7���*D�y�7O�}�W���{��~�r`���>�O�-=��Ӎ�</�������j�d-���y��^;�Ԫ&ϳq������v&�Z��ۃi����Ʈ�&�}����I~o��ɚt�Lff�n�z��Ε��c����q��_;���D��mo��G��];��f��q��\Q��J���E��k�)lp�����w��z��N�=��s�Ŧ���x��?_������"pe�z���vcn�#fV)��`��rn���f���v5P�~jl{����z��7O����v+ȹ�6bm��3ɾ���9Xd��Μt+ 0��ȵ2�Y�#�.�f�2�N ��"B�s�PE(����ۉ�VKǤx~����K�+�j�A���-}�2��#�r��~������f��������
��O��	�t��
 �O����F.N�u��(��������O틇�8���
 Y��g*�ֹ��msV�w�J������OMO�q���tX4��.�ǫ�������~ˆ��𨹚�`K��afo�6tʕ�w�ޒ��,���2K]�T�qy�6����K��U��w�~�_���q}�����o�f��1�3�5wG�}ni�s�O��_|��W����zs�� ��{ӆ����%��u׬�wf�C�0{{yw�έ��w���5<х��0�����;7@����Z���5�e�nU���U��mrn�v+�E`oT��#����0_�COU 3m~��M����ɹ�ܹ�R�b�WD��> O�M�e����kN�Ĺ��"��\!/�ʉ��1퐹�]���������m��^��J>��n{����9�B"��f����~�*��In��<;�P�?� "�s3�}��wܣXO:��������f�����7��	2�g��\
�7Ov�ŏOՅ'j5%�C @轱5������b�<�7�USZ{ˣ�g?������Q�c/�ި�t��hI��f�$^��b�����k�ͤ��*�r���4��A��iif����9���S��?�!<����6�h=�<�{yի7����,���;�]W� Ⱥ���������F�}�����{��Ѷ.���3��@�G���-yo����h�s�޿�fɱ�`o��f޷��=T;�OK��Wv��,�!�a���D���x�ö��
�f����7س^���Y�l�����x�m������ ���Io� ���*f^p�>�?�n�o|��ED�4�W�U18�X%�6�]��vۥE���	�^l
�eN.UW☹;m"5�ۡ�0m6�H�
�T{�ͽ�=UD���9G��5Y!Ȟzu�Q��܁��VK&���!��lr�
�E�z~nn���w��G���^"�G�#������f�����7����<���O���"O����O��k��c#T�ԇ 싌�=;7��U�v�b���qF���[���i=�9Ka��5u�q���&WH�j�5�)6��L�ŖU�W��w���h��{:�5�jy��{/��k�ٛ�Qoe��%o�w��:�YJ�Ǧ��Rm<:��iy?O��fWT�]�Rfq;�!1������Ͷ��p}�����o0�6�߽zI�i4X��o��V9&�s�t����e:z��N߬�#ڣ�Vu�`�w���U�t�?1�?W�5�"���v�5��x�횮�'����x\:�[����b׷W�7��d�}/�vA<�Wc��y�yى���QY��ٴ������îm���I?��*x��
\EԆ�,�]j����"���)�����g:m��.ǧ1?9�s)L;M�y~(�e��Q g��Px�K�@pTLm�:�Nq���P��~g|�g�Ф.����c*Z-���[;29����EHV��Z&��ɽ�rB�"�d�+�l26��wl2dqT"���dΉ{�W�ݳ�f�����7�o�������cϭ� �g�[N�wa�m|��o�	�.��.ON�O}nm�H�x�
����`V��an�|�;5�0綫{3�����"rɪM�~�;5��L��A���7��<ux�;7w���`U�x��43ku��i�`n��ܹ��;��JD����6Ѥ���΍��;��2�z�t<Cq��Q�>�37�JKGc#�'�Z�zo�;Z﷩���ȹ��h�kfv�Ļ���Vh���ܘ�������T��kbm��[�k1��z�`n��ׯ��܄x�+O�ޘݔL�N�F���:��vh��.7@��W{?��}��6�WTu�{��֮d���T��R���Q䦾m
/S
���ɾO;wSSsG�sH��'�{���O�����[�/A�\D]�s�'�.ےY[��.����lKvn�
��jK��d�Vvn/�IKW��R_(�z'���92���G�o���5�o������f��/Q��x*���>�@`& G��Sĸqߘ,���}���}#8zn�ب���ܷ ����7z� �$m�`�KG��O�,fEoVAKG��Q���҆e���Y���]�U?䦏�'u��]TM�I���=��'�?9l�r��F����wU"Zl��vz�G06ֺM������v����vw�v��0����sr;�Y�n����4��*��x�꽙����[�k1�OK����?��=6��o��5S{cvS������;6��RW��K���.7@��n[���M�}p�&c[y�Y���������F����p��jW
=�w�5�����p�ԋ�������Ss��������R����l��=�dG]uy򹅪-[�7���!�}�mI�"��%9w��HVO޷R�
%���R�Z�If����-2f'���_��f�����7�o��� ���~ڟ  ��O��K ��{���-b\���	��Dpϼ�<嗶F0��%?��MћUВ��ɶӲ꫾�?��-�?9l�jӂ��	�ؾ�?�҂���V\-l��ݝ�s?َ���џln�Sw����]zZpz�I�G!���{��o��� w`)������7f�ސߊ�԰�5�� w�ݵk�[NP{c����H~Anaݵ��n�d���?�g��6�Oa��07��v�ܛ��\��DĳTr�q�\$N��ٜ}���K�����vΝH��̃� wῸ�f�����q��|��g�����!�ݚ��ܛ���ގ�~q/���D��z5���Dԥ8�#����L��(k��x��"DH
j��i'�s�q6���0��_���N P�ߒ�"�K��@Do{[�	�4D��6�=(#8D��1��$���%+�3w�����k��5��G���N�������E����+�v8        [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://duic01jhq3egx"
path="res://.godot/imported/clown.png-a53cbe3fda904697a03707009ae85dcd.ctex"
metadata={
"vram_texture": false
}
               RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    radius    height    radial_segments    rings    is_hemisphere    script    size    subdivide_width    subdivide_height    subdivide_depth    custom_solver_bias    normal 	   distance 	   _bundled       PackedScene    res://entities/character.tscn bF��kb~   Script    res://Plank.gd ��������   PackedScene    res://entities/spawner.tscn bs{p+   Script    res://DebugContainer.gd ��������      local://SphereMesh_4adld b         local://BoxMesh_ko8uv �         local://RectangleShape2D_4qxbs �      #   local://WorldBoundaryShape2D_l2jq7 �         local://PackedScene_tr71w          SphereMesh             A	        �A         BoxMesh            �C  �@   A         RectangleShape2D       
     �C  �@         WorldBoundaryShape2D             PackedScene          	         names "   %      Game    Node2D    CharacterBase 	   position    status 
   left_side 	   Camera2D    Balance    Circle    mesh    MeshInstance2D    Plank    script    StaticBody2D    Mesh    CollisionShape2D    shape    Floor    SpawnerRight    SpawnerLeft    CanvasLayer    DebugContainer    anchors_preset    anchor_left    anchor_right    offset_left    offset_right    offset_bottom    grow_horizontal    CenterContainer    VBoxContainer    layout_mode    BoostMultiplicator    text    Label    BoostValue    ActionTimeElapsed    	   variants                 
                       
         ��
         `�
         @@          
          �                                             
     �C  @�       
     ��                ?     ��     �A      B                     Boost :       node_count             nodes     �   ��������       ����                ���                                              ����                           ����                    
      ����         	                       ����            	              
      ����   	   
                    ����                           ����                     ����                     ���                                 ���                                 ����                     ����                                                                    ����                    "       ����         !                 "   #   ����         !                 "   $   ����         !                conn_count              conns               node_paths              editable_instances              version             RSRC          GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�m�m۬�}�p,��5xi�d�M���)3��$�V������3���$G�$2#�Z��v{Z�lێ=W�~� �����d�vF���h���ڋ��F����1��ڶ�i�엵���bVff3/���Vff���Ҿ%���qd���m�J�}����t�"<�,���`B �m���]ILb�����Cp�F�D�=���c*��XA6���$
2#�E.@$���A.T�p )��#L��;Ev9	Б )��D)�f(qA�r�3A�,#ѐA6��npy:<ƨ�Ӱ����dK���|��m�v�N�>��n�e�(�	>����ٍ!x��y�:��9��4�C���#�Ka���9�i]9m��h�{Bb�k@�t��:s����¼@>&�r� ��w�GA����ը>�l�;��:�
�wT���]�i]zݥ~@o��>l�|�2�Ż}�:�S�;5�-�¸ߥW�vi�OA�x��Wwk�f��{�+�h�i�
4�˰^91��z�8�(��yޔ7֛�;0����^en2�2i�s�)3�E�f��Lt�YZ���f-�[u2}��^q����P��r��v��
�Dd��ݷ@��&���F2�%�XZ!�5�.s�:�!�Њ�Ǝ��(��e!m��E$IQ�=VX'�E1oܪì�v��47�Fы�K챂D�Z�#[1-�7�Js��!�W.3׹p���R�R�Ctb������y��lT ��Z�4�729f�Ј)w��T0Ĕ�ix�\�b�9�<%�#Ɩs�Z�O�mjX �qZ0W����E�Y�ڨD!�$G�v����BJ�f|pq8��5�g�o��9�l�?���Q˝+U�	>�7�K��z�t����n�H�+��FbQ9���3g-UCv���-�n�*���E��A�҂
�Dʶ� ��WA�d�j��+�5�Ȓ���"���n�U��^�����$G��WX+\^�"�h.���M�3�e.
����MX�K,�Jfѕ*N�^�o2��:ՙ�#o�e.
��p�"<W22ENd�4B�V4x0=حZ�y����\^�J��dg��_4�oW�d�ĭ:Q��7c�ڡ��
A>��E�q�e-��2�=Ϲkh���*���jh�?4�QK��y@'�����zu;<-��|�����Y٠m|�+ۡII+^���L5j+�QK]����I �y��[�����(}�*>+���$��A3�EPg�K{��_;�v�K@���U��� gO��g��F� ���gW� �#J$��U~��-��u���������N�@���2@1��Vs���Ŷ`����Dd$R�":$ x��@�t���+D�}� \F�|��h��>�B�����B#�*6��  ��:���< ���=�P!���G@0��a��N�D�'hX�׀ "5#�l"j߸��n������w@ K�@A3�c s`\���J2�@#�_ 8�����I1�&��EN � 3T�����MEp9N�@�B���?ϓb�C��� � ��+�����N-s�M�  ��k���yA 7 �%@��&��c��� �4�{� � �����"(�ԗ�� �t�!"��TJN�2�O~� fB�R3?�������`��@�f!zD��%|��Z��ʈX��Ǐ�^�b��#5� }ى`�u�S6�F�"'U�JB/!5�>ԫ�������/��;	��O�!z����@�/�'�F�D"#��h�a �׆\-������ Xf  @ �q�`��鎊��M��T�� ���0���}�x^�����.�s�l�>�.�O��J�d/F�ě|+^�3�BS����>2S����L�2ޣm�=�Έ���[��6>���TъÞ.<m�3^iжC���D5�抺�����wO"F�Qv�ږ�Po͕ʾ��"��B��כS�p�
��E1e�������*c�������v���%'ž��&=�Y�ް>1�/E������}�_��#��|������ФT7׉����u������>����0����緗?47�j�b^�7�ě�5�7�����|t�H�Ե�1#�~��>�̮�|/y�,ol�|o.��QJ rmϘO���:��n�ϯ�1�Z��ը�u9�A������Yg��a�\���x���l���(����L��a��q��%`�O6~1�9���d�O{�Vd��	��r\�՜Yd$�,�P'�~�|Z!�v{�N�`���T����3?DwD��X3l �����*����7l�h����	;�ߚ�;h���i�0�6	>��-�/�&}% %��8���=+��N�1�Ye��宠p�kb_����$P�i�5�]��:��Wb�����������ě|��[3l����`��# -���KQ�W�O��eǛ�"�7�Ƭ�љ�WZ�:|���є9�Y5�m7�����o������F^ߋ������������������Р��Ze�>�������������?H^����&=����~�?ڭ�>���Np�3��~���J�5jk�5!ˀ�"�aM��Z%�-,�QU⃳����m����:�#��������<�o�����ۇ���ˇ/�u�S9��������ٲG}��?~<�]��?>��u��9��_7=}�����~����jN���2�%>�K�C�T���"������Ģ~$�Cc�J�I�s�? wڻU���ə��KJ7����+U%��$x�6
�$0�T����E45������G���U7�3��Z��󴘶�L�������^	dW{q����d�lQ-��u.�:{�������Q��_'�X*�e�:�7��.1�#���(� �k����E�Q��=�	�:e[����u��	�*�PF%*"+B��QKc˪�:Y��ـĘ��ʴ�b�1�������\w����n���l镲��l��i#����!WĶ��L}rեm|�{�\�<mۇ�B�HQ���m�����x�a�j9.�cRD�@��fi9O�.e�@�+�4�<�������v4�[���#bD�j��W����֢4�[>.�c�1-�R�����N�v��[�O�>��v�e�66$����P
�HQ��9���r�	5FO� �<���1f����kH���e�;����ˆB�1C���j@��qdK|
����4ŧ�f�Q��+�     [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://b17lg61y5cmlj"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                extends StaticBody2D
class_name Plank

signal release()

const TILT_ANGLE = PI * 0.1

func get_half_size():
	return $CollisionShape2D.shape.size.x * 0.5


func tilt(left_side):
	var t = create_tween()
	t.tween_property(self,"rotation",-TILT_ANGLE if left_side else TILT_ANGLE,0.12)
	t.tween_callback(self._on_tilt_end)

func _on_tilt_end():
	print("Tilt")
	release.emit()
            extends CenterContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	ActionPressManager.boost_proceed.connect(self._update_boost_multiplicator_values)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _update_boost_multiplicator_values():
	$VBoxContainer/BoostValue.text = "Boost Value : %.2f" % [ActionPressManager.get_boost_value()]
	$VBoxContainer/BoostMultiplicator.text = "Boost : %.2f" % [ActionPressManager.get_boost_multiplicator()]
	$VBoxContainer/ActionTimeElapsed.text = "Boost time : %.2f" % [ActionPressManager.get_elapsed_time_last_action()]
 [remap]

path="res://.godot/exported/133200997/export-d1ef8fc1c8d8fa2f03d8205403f4d680-character.scn"
          [remap]

path="res://.godot/exported/133200997/export-38ac771870673db8cfcbb0a8bc96a1ba-spawner.scn"
            [remap]

path="res://.godot/exported/133200997/export-609f762188a68253d349ec58c4f3a8d3-game.scn"
               list=Array[Dictionary]([{
"base": &"StaticBody2D",
"class": &"Plank",
"icon": "",
"language": &"GDScript",
"path": "res://Plank.gd"
}])
        <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z" fill="#478cbf"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
              bF��kb~   res://entities/character.tscnbs{p+   res://entities/spawner.tscnd�t�&E�P   res://game.tscn�A�P��^;   res://icon.svg�Ig�(Kw   res://img/clown.png        ECFG      application/config/name         CircusMarmelade    application/run/main_scene         res://game.tscn    application/config/features$   "         4.2    Forward Plus       application/config/icon         res://icon.svg     autoload/ActionPressManager0      &   *res://globals/action_press_manager.gd     editor/movie_writer/movie_fileT      I   C:/Users/jonas/Workspace/Jams/CircusMarmelade/_video_export/recording.avi   
   input/left�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/right�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script         input/action�              events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode       	   key_label             unicode           echo          script            deadzone      ?   input/rotate_positive�              events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script            deadzone      ?   input/rotate_negative�              events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script            deadzone      ?     