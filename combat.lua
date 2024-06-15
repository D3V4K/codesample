--Variables
local Punch1 = script.Punch1
local Punch2 = script.Punch2
local Punch3 = script.Punch3
local Punch4 = script.Punch4
local Block = script.Block
local Swing = script.Swing
local Impact = script.Impact
local lastattack = time()
local Punch1AnimTrack
local Punch2AnimTrack
local Punch3AnimTrack
local Punch4AnimTrack
local knockbackpower
local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')
--Modifiable Variables
local RagdollTime = 2
local KnockbackDuartion = 0.5
local HitboxDuration = 0.1
local damage = 10
local BlockCD = 1
--Tables
local playerDebounce = {}
local HitboxDebounce = {}
local BlockDebounce = {}
local PlayerAnimTracks = {}
--Functions
local function ActivateRagdoll(char)--Ragdoll by deafctivating motor6d and adding ballsocketconstraints to joints
	if char:GetAttribute('Ragdoll') then return end
	local humanoid = char.Humanoid
	local hrp = char:FindFirstChild('HumanoidRootPart')
	for i, joint in pairs(char:GetDescendants()) do
		if joint:IsA('Motor6D') then
			local BSC = Instance.new('BallSocketConstraint')
			local a1 = Instance.new('Attachment')
			local a2 = Instance.new('Attachment')
			BSC.Parent = joint.Parent
			BSC.Attachment0 = a1
			BSC.Attachment1 = a2
			a1.CFrame = joint.C0
			a2.CFrame = joint.C1
			a1.Parent = joint.Part0
			a2.Parent = joint.Part1
			BSC.LimitsEnabled = true
			BSC.TwistLimitsEnabled = true
			joint.Enabled = false
		end
	end
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	char:SetAttribute('Ragdoll', true)
end

local function DeactivateRagdoll(char)--Deactivates ragdoll by deleting ballsocketconstraints and reenable motor6ds
	if char:GetAttribute('Ragdoll') == false then return end
	local humanoid = char.Humanoid
	for i, joint in pairs(char:GetDescendants()) do
		if joint:IsA('BallSocketConstraint') then
			joint:Destroy()
		elseif joint:IsA('Motor6D') then
			joint.Enabled = true		
		end
	end
	humanoid.WalkSpeed = 16
	humanoid.JumpHeight = 7.2
	humanoid.AutoRotate = true
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	char:SetAttribute('Ragdoll', false)
end

local function knockback(playerchar, enemychar, power)--Knockback using AssemblyLinearVelocity
	local playerhrp = playerchar.HumanoidRootPart
	local enemyhrp = enemychar.HumanoidRootPart
	enemyhrp.AssemblyLinearVelocity = playerhrp.CFrame.LookVector * power
end

local function createHitbox(HitboxOriginPart)--Create a hitbox 
	local Hitbox = Instance.new("Part")
	Hitbox.Size = Vector3.new(8,8,8)
	Hitbox.CFrame = HitboxOriginPart.CFrame * CFrame.new(0,1,0)
	Hitbox.Anchored = true
	Hitbox.Transparency = 1
	Hitbox.CanCollide = false
	Hitbox.Parent = workspace
	return Hitbox
end

local function PlaySFX(sound, parent)--Play a sound effect
	local clonedSFX = sound:Clone()
	clonedSFX.Parent = parent
	clonedSFX:Play()
	Debris:AddItem(clonedSFX, clonedSFX.TimeLength)
end

game.Players.PlayerAdded:Connect(function(player)-- Preload animations and add players to debounce table
	player.CharacterAdded:Connect(function(char) 
		playerDebounce[player] = false
		BlockDebounce[player] = false
		local animator = char.Humanoid:FindFirstChild('Animator')
		PlayerAnimTracks[player] = {}
		PlayerAnimTracks[player].Punch1 = animator:LoadAnimation(Punch1)
		PlayerAnimTracks[player].Punch2 = animator:LoadAnimation(Punch2)
		PlayerAnimTracks[player].Punch3 = animator:LoadAnimation(Punch3)
		PlayerAnimTracks[player].Punch4 = animator:LoadAnimation(Punch4)
		PlayerAnimTracks[player].Block = animator:LoadAnimation(Block)
	end)	
end)

game.Players.PlayerRemoving:Connect(function(player)--Remove players from debounce table
	playerDebounce[player] = nil
	BlockDebounce[player] = nil
end)

game.ReplicatedStorage.RE.M1.OnServerEvent:Connect(function(player)--Punch Function
	local char = player.Character
	local combo = char:GetAttribute('Combo')
	if time()-lastattack > 2 then--Reset Attack If Enough Time Elapsed
		char:SetAttribute('Combo', 1)
	end
	if char:GetAttribute('WeaponEquipped') then return end--Checking Stuff
	if char:GetAttribute('Blocking') then return end
	if char:GetAttribute('Ragdoll') then return end
	if playerDebounce[player] then return end
	local char = player.Character--Variables
	local hrp = char.HumanoidRootPart
	local animationtrack
	local hand
	local nextcombo
	local ragdollonpunch
	if combo == 1 then--Set some predetermined values for each punch 
		animationtrack = PlayerAnimTracks[player].Punch1
		hand = char.RightHand
		nextcombo = combo+1
		knockbackpower = 40
		ragdollonpunch = false
	elseif combo == 2 then
		animationtrack = PlayerAnimTracks[player].Punch2
		hand = char.LeftHand
		nextcombo = combo+1
	elseif combo == 3 then
		animationtrack = PlayerAnimTracks[player].Punch3
		hand = char.RightHand
		nextcombo = combo+1
	elseif combo == 4 then
		animationtrack = PlayerAnimTracks[player].Punch4
		hand = char.LeftHand
		nextcombo = 1
		knockbackpower = 150
		ragdollonpunch = true
	end
	animationtrack:Play()--Main Function	
	playerDebounce[player] = true
	PlaySFX(Swing, hand)
	animationtrack:GetMarkerReachedSignal('Impact'):Connect(function()
		local hitbox = createHitbox(hand)
		Debris:AddItem(hitbox, HitboxDuration)
		hitbox.Touched:Connect(function(part)
			local EnemyChar = part.Parent
			local humanoid = EnemyChar:FindFirstChild('Humanoid')
			if humanoid and EnemyChar ~= char and (HitboxDebounce[EnemyChar] == false or HitboxDebounce[EnemyChar] == nil) then
				HitboxDebounce[EnemyChar] = true--Debounce system to prevent multiple attacks on the same part on the same hitbox
				if EnemyChar:GetAttribute('Blocking') == true and (EnemyChar.Shield.Position - hrp.Position).Magnitude < (EnemyChar.HumanoidRootPart.Position - hrp.Position).Magnitude then--Check if enemy is blocking by checking whether the shield or the humanoidroot part is closer to attacking player
					PlaySFX(Impact, hand)					
				else
					humanoid.Health = humanoid.Health - damage
					PlaySFX(Impact, hand)
					knockback(player.Character, EnemyChar, knockbackpower)
					if ragdollonpunch then ActivateRagdoll(EnemyChar) task.wait(RagdollTime) DeactivateRagdoll(EnemyChar) end
				end
			end
		end)
		hitbox.AncestryChanged:Connect(function()--Reset the hitbox debounce for the next punch
			HitboxDebounce = {}
		end)
	end)
	animationtrack.Stopped:Wait()
	playerDebounce[player] = false
	char:SetAttribute('Combo', nextcombo)
	lastattack = time()
end)

local ShieldSpawnTween = nil--Global variables made so that spamming block doesn't bug out the system
local ShieldDisappearTween = nil
game.ReplicatedStorage.RE.Block.OnServerEvent:Connect(function(player, state)--Block function
	local BlockTrack = PlayerAnimTracks[player].Block
	local char = player.Character
	if BlockDebounce[player] == true then return end--Block Cooldown System
	if state then
		if char then--Blocking
			if ShieldDisappearTween ~= nil then ShieldDisappearTween:Pause() ShieldDisappearTween:Destroy() ShieldDisappearTween = nil end --Piece of code that cancels the disappear tween when the block button is spammed
			BlockTrack:Play()		
			BlockTrack:GetMarkerReachedSignal('Block'):Connect(function()
				BlockTrack:AdjustSpeed(0)
			end)
			local Shield = char.Shield
			Shield.Transparency = 0.75
			ShieldSpawnTween = TweenService:Create(Shield, TweenInfo.new(0.25), {Size = Vector3.new(0.219, 6.75, 3.5)})
			ShieldSpawnTween:Play()
			ShieldSpawnTween.Completed:Connect(function()
				ShieldSpawnTween = nil
				char:SetAttribute("Blocking", true)
			end)
		end
	else
		if char then--Not blocking
			BlockDebounce[player] = true
			if ShieldSpawnTween ~= nil then ShieldSpawnTween:Pause() ShieldSpawnTween:Destroy() ShieldSpawnTween = nil end --Piece of code that cancels the appear tween when the block button is spammed
			char:SetAttribute("Blocking", false)
			BlockTrack:Stop()
			local Shield = char.Shield
			ShieldDisappearTween = TweenService:Create(Shield, TweenInfo.new(0.25), {Size = Vector3.new(0.219, 6.75, 0.125)})
			ShieldDisappearTween:Play()
			ShieldDisappearTween.Completed:Wait()
			Shield.Transparency = 1
			task.wait(BlockCD)
			BlockDebounce[player] = false
		end
	end
end)
