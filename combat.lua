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
local Punch = {}
local playerDebounce = {}
local HitboxDebounce = {}
local BlockDebounce = {}
local PlayerAnimTracks = {}
--Metatable
local PunchConfig = {--Creating "Punch" object to customize each of the 4 different punches
	Animationtrack = nil,
	Hand = nil,
	NextCombo = 1,
	knockbackpower = 40,
	ragdollonpunch = false,	
}
PunchConfig.__index = PunchConfig
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
	print(parent.Name)
	local clonedSFX = sound:Clone()
	clonedSFX.Parent = parent
	clonedSFX:Play()
	Debris:AddItem(clonedSFX, clonedSFX.TimeLength)
end

--Metatable Functions
function PunchConfig.new(newtable)
	return setmetatable(newtable, PunchConfig)
end

function PunchConfig:Attack(player)--Main Function of M1 attack
	local char = player.Character
	local hrp = char.HumanoidRootPart
	self.Animationtrack:Play()
	playerDebounce[player] = true
	PlaySFX(Swing, self.Hand)
	self.Animationtrack:GetMarkerReachedSignal('Impact'):Connect(function()
		local hitbox = createHitbox(self.Hand)
		Debris:AddItem(hitbox, HitboxDuration)
		hitbox.Touched:Connect(function(part)
			local EnemyChar = part.Parent
			local humanoid = EnemyChar:FindFirstChild('Humanoid')
			if humanoid and EnemyChar ~= char and (HitboxDebounce[EnemyChar] == false or HitboxDebounce[EnemyChar] == nil) then
				HitboxDebounce[EnemyChar] = true--Debounce system to prevent multiple attacks on the same part on the same hitbox
				if EnemyChar:GetAttribute('Blocking') == true and (EnemyChar.Shield.Position - hrp.Position).Magnitude < (EnemyChar.HumanoidRootPart.Position - hrp.Position).Magnitude then--Check if enemy is blocking by checking whether the shield or the humanoidroot part is closer to attacking player
					PlaySFX(Impact, self.Hand)					
				else
					humanoid.Health = humanoid.Health - damage
					PlaySFX(Impact, self.Hand)
					knockback(player.Character, EnemyChar, self.knockbackpower)
					if self.ragdollonpunch then ActivateRagdoll(EnemyChar) task.wait(RagdollTime) DeactivateRagdoll(EnemyChar) end
				end
			end
		end)
		hitbox.AncestryChanged:Connect(function()--Reset the hitbox debounce for the next punch
			HitboxDebounce = {}
		end)
	end)
	self.Animationtrack.Stopped:Wait()
	playerDebounce[player] = false
	char:SetAttribute('Combo', self.NextCombo)
	lastattack = time()
end

--Signals
game.Players.PlayerAdded:Connect(function(player)-- Preload animations and add players to debounce table
	player.CharacterAdded:Connect(function(char) 
		playerDebounce[player] = false
		BlockDebounce[player] = false
		local animator = char.Humanoid:FindFirstChild('Animator')
		PlayerAnimTracks[player] = {}
		Punch[player] = {}
		PlayerAnimTracks[player].Block = animator:LoadAnimation(Block)
		Punch[player].Punch1 = PunchConfig.new({Animationtrack = animator:LoadAnimation(Punch1), Hand = char.RightHand, NextCombo = 2})--Customize each of the punches here
		Punch[player].Punch2 = PunchConfig.new({Animationtrack = animator:LoadAnimation(Punch2), Hand = char.LeftHand, NextCombo = 3})	
		Punch[player].Punch3 = PunchConfig.new({Animationtrack = animator:LoadAnimation(Punch3), Hand = char.RightHand, NextCombo =4})	
		Punch[player].Punch4 = PunchConfig.new({Animationtrack = animator:LoadAnimation(Punch4), Hand = char.LeftHand, knockbackpower=150, ragdollonpunch=true})	
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
	local punch
	if combo == 1 then--Use previously determined punches according to current combo
		Punch[player].Punch1:Attack(player)
	elseif combo == 2 then
		Punch[player].Punch2:Attack(player)
	elseif combo == 3 then
		Punch[player].Punch3:Attack(player)
	elseif combo == 4 then
		Punch[player].Punch4:Attack(player)
	end
end)

local ShieldSpawnTween = nil--Global variables made so that spamming block doesn't bug out the system
local ShieldDisappearTween = nil
game.ReplicatedStorage.RE.Block.OnServerEvent:Connect(function(player, state)--Block function
	local BlockTrack = PlayerAnimTracks[player].Block
	local char = player.Character
	if BlockDebounce[player] == true then return end--Block Cooldown System
	if state then
		if char then--Blocking
			if ShieldDisappearTween ~= nil then ShieldDisappearTween:Pause() ShieldDisappearTween:Destroy() ShieldDisappearTween = nil end--Piece of code that cancels the disappear tween when the block button is spammed
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
			if ShieldSpawnTween ~= nil then ShieldSpawnTween:Pause() ShieldSpawnTween:Destroy() ShieldSpawnTween = nil end--Piece of code that cancels the appear tween when the block button is spammed
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
