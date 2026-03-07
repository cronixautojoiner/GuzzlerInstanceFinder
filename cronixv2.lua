task.wait(4.5)

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer
local UI_NAME = "Cronix_Flashpoint_UI"
local FRAME_WIDTH = 260
local FRAME_BASE_HEIGHT = 206
local TELEPORT_COOLDOWN = 0.25
local SAVE_COOLDOWN = 0.35
local MIN_RECOMMENDED_SPEED = 1
local MAX_RECOMMENDED_SPEED = 100
local FLASHTIME_WARNING = "Do not use extra speed with FlashTime mode or youll be in risk."
local FLASHTIME_DISCLAIMER = "Disclaimer: " .. FLASHTIME_WARNING

local COLORS = {
	Frame = Color3.fromRGB(15, 15, 15),
	Stroke = Color3.fromRGB(200, 0, 0),
	Button = Color3.fromRGB(120, 0, 0),
	Neutral = Color3.fromRGB(25, 25, 25),
	White = Color3.fromRGB(255, 255, 255),
	Title = Color3.fromRGB(220, 40, 40),
	Section = Color3.fromRGB(200, 200, 200),
	Placeholder = Color3.fromRGB(150, 150, 150),
}

local function toast(title, text, duration)
	pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
		Title = title or "Cronix",
		Text = text or "",
		Duration = duration or 2,
	})
end

local function safeDestroyExistingUi()
	local old = CoreGui:FindFirstChild(UI_NAME)
	if old then
		old:Destroy()
	end
end

safeDestroyExistingUi()

local cachedRU
local cachedAdminAbuse
local cachedCharacter
local cachedHRP

local function resolveRebirthUpgrades()
	if cachedRU and cachedRU.Parent then
		return cachedRU
	end

	local playerData = LOCAL_PLAYER:FindFirstChild("PlayerData") or LOCAL_PLAYER:WaitForChild("PlayerData", 5)
	if not playerData then
		return nil
	end

	cachedRU = playerData:FindFirstChild("RebirthUpgrades") or playerData:WaitForChild("RebirthUpgrades", 5)
	return cachedRU
end

local function resolveAdminAbuse()
	if cachedAdminAbuse and cachedAdminAbuse.Parent then
		return cachedAdminAbuse
	end

	cachedAdminAbuse = Workspace:FindFirstChild("AdminAbuse") or Workspace:FindFirstChild("AdminAbuse", true)
	return cachedAdminAbuse
end

local function resolveHRP()
	local character = LOCAL_PLAYER.Character
	if character ~= cachedCharacter then
		cachedCharacter = character
		cachedHRP = nil
	end

	if not character then
		return nil
	end

	if cachedHRP and cachedHRP.Parent == character then
		return cachedHRP
	end

	cachedHRP = character:FindFirstChild("HumanoidRootPart")
	return cachedHRP
end

local function applyAllRebirthValues(value)
	local rebirthUpgrades = resolveRebirthUpgrades()
	if not rebirthUpgrades then
		toast("Cronix", "RebirthUpgrades NOT FOUND", 2)
		return false, 0
	end

	local updatedCount = 0
	for _, child in rebirthUpgrades:GetChildren() do
		if child:IsA("IntValue") and child.Value ~= value then
			child.Value = value
			updatedCount = updatedCount + 1
		end
	end

	return true, updatedCount
end

local function getObjectCFrame(object)
	if object:IsA("Model") then
		return object:GetPivot()
	end
	if object:IsA("BasePart") then
		return object.CFrame
	end
	return nil
end

local lastTeleport = 0
local function teleportToAdminAbuse(targetName, label)
	local now = os.clock()
	if now - lastTeleport < TELEPORT_COOLDOWN then
		return
	end
	lastTeleport = now

	local adminAbuse = resolveAdminAbuse()
	if not adminAbuse then
		toast(label or "Admin Abuse", "AdminAbuse NOT FOUND", 2)
		return
	end

	local target = adminAbuse:FindFirstChild(targetName)
	if not target then
		toast(label or "Admin Abuse", targetName .. " NOT FOUND", 2)
		return
	end

	local targetCFrame = getObjectCFrame(target)
	if not targetCFrame then
		toast(label or "Admin Abuse", "Target has no valid position", 2)
		return
	end

	local hrp = resolveHRP()
	if not hrp then
		toast(label or "Admin Abuse", "HRP missing", 2)
		return
	end

	hrp.CFrame = targetCFrame * CFrame.new(0, 5, 0)
end

local function applyCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
end

local function createLabel(parent, text, height, font, textSize, textColor)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = font
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = textColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = parent
	return label
end

local function createButton(parent, text, height, backgroundColor)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, height)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextSize = 14
	button.TextColor3 = COLORS.White
	button.BackgroundColor3 = backgroundColor or COLORS.Button
	button.ZIndex = 11
	button.Parent = parent
	applyCorner(button, 8)
	return button
end

local function createInput(parent, placeholder, height)
	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, 0, 0, height)
	input.BorderSizePixel = 0
	input.BackgroundColor3 = COLORS.Neutral
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.Gotham
	input.Text = ""
	input.PlaceholderText = placeholder
	input.TextSize = 14
	input.TextColor3 = COLORS.White
	input.PlaceholderColor3 = COLORS.Placeholder
	input.ZIndex = 11
	input.Parent = parent
	applyCorner(input, 8)
	return input
end

local function parseSpeed(text)
	local trimmed = string.match(text or "", "^%s*(.-)%s*$")
	local number = tonumber(trimmed)
	if not number then
		return nil
	end
	return math.floor(number + 0.5)
end

local ui = Instance.new("ScreenGui")
ui.Name = UI_NAME
ui.IgnoreGuiInset = true
ui.ResetOnSpawn = false
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_BASE_HEIGHT)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = COLORS.Frame
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ZIndex = 10
frame.Parent = ui
applyCorner(frame, 12)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = COLORS.Stroke
stroke.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = frame

local title = createLabel(frame, "Cronix - Flashpoint", 24, Enum.Font.GothamBold, 15, COLORS.Title)
title.LayoutOrder = 1

local disclaimer = createLabel(frame, FLASHTIME_DISCLAIMER, 30, Enum.Font.Gotham, 11, COLORS.Section)
disclaimer.LayoutOrder = 2
disclaimer.TextWrapped = true
disclaimer.TextYAlignment = Enum.TextYAlignment.Top

local input = createInput(frame, "Speed value (" .. MIN_RECOMMENDED_SPEED .. "-" .. MAX_RECOMMENDED_SPEED .. "):", 32)
input.LayoutOrder = 3

local saveButton = createButton(frame, "Save", 32)
saveButton.LayoutOrder = 4

local lastSave = 0
saveButton.MouseButton1Click:Connect(function()
	local now = os.clock()
	if now - lastSave < SAVE_COOLDOWN then
		return
	end
	lastSave = now

	local value = parseSpeed(input.Text)
	if not value then
		toast("Cronix", "Enter a number", 2)
		return
	end

	if value < MIN_RECOMMENDED_SPEED then
		toast("Cronix", "Minimum speed is " .. MIN_RECOMMENDED_SPEED, 3)
		return
	end

	if value > MAX_RECOMMENDED_SPEED then
		toast("DISCLAIMER", FLASHTIME_WARNING, 5)
		return
	end

	local ok, updatedCount = applyAllRebirthValues(value)
	if not ok then
		return
	end

	input.Text = tostring(value)
	if updatedCount > 0 then
		toast("Cronix", "Saved speed: " .. value, 2)
	else
		toast("Cronix", "Speed already set to " .. value, 2)
	end
end)

local dropdownHeader = Instance.new("Frame")
dropdownHeader.Size = UDim2.new(1, 0, 0, 28)
dropdownHeader.BackgroundTransparency = 1
dropdownHeader.LayoutOrder = 5
dropdownHeader.Parent = frame

local dropdownButton = createButton(dropdownHeader, "Admin Abuse  ▸", 28, COLORS.Neutral)

local dropdownContent = Instance.new("Frame")
dropdownContent.Size = UDim2.new(1, 0, 0, 0)
dropdownContent.BackgroundTransparency = 1
dropdownContent.ClipsDescendants = true
dropdownContent.LayoutOrder = 6
dropdownContent.Parent = frame

local dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Padding = UDim.new(0, 8)
dropdownLayout.Parent = dropdownContent

local cometButton = createButton(dropdownContent, "TP TO COMET", 32)
cometButton.LayoutOrder = 1
cometButton.MouseButton1Click:Connect(function()
	teleportToAdminAbuse("Comet", "Comet TP")
end)

local riftButton = createButton(dropdownContent, "TP TO RIFT", 32)
riftButton.LayoutOrder = 2
riftButton.MouseButton1Click:Connect(function()
	teleportToAdminAbuse("Rift", "Rift TP")
end)

local section = createLabel(dropdownContent, "Find suit", 18, Enum.Font.GothamBold, 12, COLORS.Section)
section.LayoutOrder = 3

local suitButton = createButton(dropdownContent, "TP TO SUIT", 32)
suitButton.LayoutOrder = 4
suitButton.MouseButton1Click:Connect(function()
	teleportToAdminAbuse("RiftsRig", "Find suit")
end)

local expanded = false
local dropdownContentHeight = 0

local function refreshContainerHeight()
	local visibleHeight = expanded and dropdownContentHeight or 0
	dropdownContent.Size = UDim2.new(1, 0, 0, visibleHeight)
	frame.Size = UDim2.fromOffset(FRAME_WIDTH, FRAME_BASE_HEIGHT + visibleHeight)
end

dropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	dropdownContentHeight = dropdownLayout.AbsoluteContentSize.Y
	refreshContainerHeight()
end)

local function setDropdownState(state)
	expanded = state
	dropdownButton.Text = expanded and "Admin Abuse  ▾" or "Admin Abuse  ▸"
	refreshContainerHeight()
end

dropdownButton.MouseButton1Click:Connect(function()
	setDropdownState(not expanded)
end)

dropdownContentHeight = dropdownLayout.AbsoluteContentSize.Y
setDropdownState(false)
toast("Disclaimer", FLASHTIME_WARNING, 5)
