-- PASTE INTO: ReplicatedStorage > Modules > SharedUtils (ModuleScript)

local SharedUtils = {}

local HEAD_PART_NAMES = {
	Head = true,
	head = true,
}

function SharedUtils.isHeadPart(part: BasePart): boolean
	if not part then
		return false
	end
	if HEAD_PART_NAMES[part.Name] then
		return true
	end
	return part:GetAttribute("IsHead") == true
end

function SharedUtils.getHumanoidFromHit(hit: Instance?): Humanoid?
	if not hit then
		return nil
	end
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return model:FindFirstChildOfClass("Humanoid")
end

function SharedUtils.applySpread(direction: Vector3, spread: number): Vector3
	local dx = (math.random() - 0.5) * 2 * spread
	local dy = (math.random() - 0.5) * 2 * spread
	local dz = (math.random() - 0.5) * 2 * spread
	local dir = direction + Vector3.new(dx, dy, dz)
	if dir.Magnitude < 0.001 then
		return direction.Unit
	end
	return dir.Unit
end

function SharedUtils.raycast(origin: Vector3, direction: Vector3, range: number, ignoreList: { Instance })
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true
	return workspace:Raycast(origin, direction.Unit * range, params)
end

return SharedUtils
