-- =======================================================================================
-- 'Easy Shade' Script Usage Guide for Aseprite
-- =======================================================================================

-- SETUP:
-- 1. Transfer this script file to Aseprite's script directory. Navigate via:
--    File > Scripts > Open Scripts Folder.
-- 2. To activate the script, head to: File > Scripts > Easy Shade.
--    This action displays the shading palette window.

-- SHORTCUT SUGGESTION:
-- For swift access to 'Easy Shade', consider mapping it to a keyboard shortcut:
--    a. I recommend the ~ key (found right below the Esc key).
--    b. To assign the shortcut, go to: Edit > Keyboard Shortcuts in Aseprite.
--       Locate 'Easy Shade' and allocate your preferred key.

-- COMMANDS & FUNCTIONS:
-- Foreground and Background:
--    • Click either of the two base colors to toggle the shading palette to the corresponding saved color base.
-- Clicking on Colors:
--    • Left Click: Designate the selected color as your foreground color.
--    • Right Click: Designate the selected color as your background color.
--    • Middle Click: Appoint the clicked color as foreground and reformulate shades based on it.
-- Get Button:
--    • Activate this to update base colors, drawing from Aseprite's current foreground and background colors.
--      The shading palette regenerates automatically.

-- =======================================================================================

--⁡⁢⁣⁢----------------------------------------⁡-
--                ⁡⁢⁣⁢𝗩𝗔𝗥𝗜𝗔𝗕𝗟𝗘𝗦⁡              --
--⁡⁢⁣⁢---------------------------------------⁡--

local colorDialog = nil
local autoUpdateOnPick, useEyeDropper = true, true
local foregroundColorListener, backgroundColorListener = nil, nil
local shadeIntensityFactor = 50
local availableColorHarmonies = { "None", "Complementary", "Split Complementary", "Triadic", "Tetradic", "Square" }

-- Base Colors and Shades
local foregroundColor, backgroundColor = nil, nil
local complementaryColor = nil
local splitComplementaryColors, triadicColors = nil, nil
local tetradicColors, squareColors = nil, nil
local basePositiveShadeColors, baseNegativeShadeColors = {}, {}
local brightnessColors, saturationColors, hueColors =  {}, {}, {}

-- Harmony Colors
local harmony1PositiveShadeColors, harmony1NegativeShadeColors = {}, {}
local harmony2PositiveShadeColors, harmony2NegativeShadeColors  = {}, {}
local harmony3PositiveShadeColors, harmony3NegativeShadeColors = {}, {}

-- Shade Values
local shadePositiveValues = {1, 0.8, 0.6, 0.4, 0.2, 0.1, 0, 0, -0.1, -0.2, -0.4, -0.6, -0.8, -1}
local shadeNegativeValues = {-1, -0.8, -0.6, -0.4, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.4, 0.6, 0.8, 1}
local shadeSaturationValues = {0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0, 0, 0, 0, 0, 0, 0, 0}
local shadeBrightnessValues = {-0.8, -0.7, -0.6, -0.4, -0.3, -0.2, 0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6}
local brightnessValues = {-1, -0.8, -0.6, -0.4, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.4, 0.6, 0.8, 1}
local saturationValues = {-1, -0.8, -0.6, -0.4, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.4, 0.6, 0.8, 1}
local hueValues = {-1, -0.8, -0.6, -0.4, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.4, 0.6, 0.8, 1}


--⁡⁢⁣⁢---------------------------------------⁡--
--              ⁡⁢⁣⁢𝗖𝗔𝗟𝗖𝗨𝗟𝗔𝗧𝗜𝗢𝗡⁡             --
--⁡⁢⁣⁢---------------------------------------⁡--

--⁡⁢⁣⁡⁢⁣⁣---------------------------------------⁡⁡--
--               ⁡⁢⁣⁣𝘏𝘈𝘙𝘔𝘖𝘕𝘐𝘌𝘚⁡               --
--⁡⁢⁣⁣---------------------------------------⁡⁡--

local function generateHarmonizedColors(color, hueOffsets)
  local colors = {}
  for _, offset in ipairs(hueOffsets) do
    local newColor = Color(color)
    newColor.hslHue = (newColor.hslHue + offset) % 360
    table.insert(colors, newColor)
  end
  return colors
end

local function refreshHarmonyColors()
  complementaryColor = generateHarmonizedColors(app.fgColor, {180})[1]
  splitComplementaryColors = generateHarmonizedColors(app.fgColor, {150, 210})
  triadicColors = generateHarmonizedColors(app.fgColor, {120, 240})
  tetradicColors = generateHarmonizedColors(app.fgColor, {45, 180, 225})
  squareColors = generateHarmonizedColors(app.fgColor, {90, 180, 270})
end

--⁡⁢⁣⁣---------------------------------------⁡--
--             ⁡⁢⁣⁣𝘚𝘏𝘐𝘍𝘛 𝘗𝘈𝘛𝘛𝘌𝘙𝘕𝘚 ⁡           --
--⁡⁢⁣⁣---------------------------------------⁡--
local function createShadeShiftPatterns()
  local positiveShifts = {}
  local negativeShifts = {}

  for i = 1, 14 do
      table.insert(positiveShifts, {shd=shadePositiveValues[i], sat=shadeSaturationValues[i], bri=shadeBrightnessValues[i], hue=0 })
      table.insert(negativeShifts, {shd=shadeNegativeValues[i], sat=shadeSaturationValues[i], bri=shadeBrightnessValues[i], hue=0 })
  end

  return positiveShifts, negativeShifts
end

local function createAttributeShiftPatterns(params)
  local shifts = {}

  for i = 1, #params.values do
    local hash = {shd=0, sat=0, bri=0, hue=0}
    hash[params.attribute] = params.values[i]
    table.insert(shifts, hash)
  end

  return shifts
end

local positiveShadeShifts, negativeShadeShifts = createShadeShiftPatterns()
local brightnessShifts = createAttributeShiftPatterns({attribute="bri", values=brightnessValues})
local saturationShifts = createAttributeShiftPatterns({attribute="sat", values=saturationValues})
local hueShifts = createAttributeShiftPatterns({attribute="hue", values=hueValues})

--⁡⁢⁣⁣---------------------------------------⁡--
--            ⁡⁢⁣⁣ 𝘏𝘚𝘓 & 𝘚𝘏𝘈𝘋𝘌𝘚    ⁡          --
--⁡⁢⁣⁣---------------------------------------⁡--

local function blendTowardsTargetValue(currentValue, targetValue, shiftAmount)
  return currentValue * (1 - shiftAmount) + targetValue * shiftAmount
end

local function adjustColorAttributes(color, hueShift, satShift, lightShift, shadeShift)
  local newColor = Color(color)

  newColor.hslHue = (newColor.hslHue + hueShift * 100 + shadeShift * shadeIntensityFactor) % 360
  newColor.saturation = blendTowardsTargetValue(newColor.saturation, satShift > 0 and 1 or 0, math.abs(satShift))
  newColor.lightness = blendTowardsTargetValue(newColor.lightness, lightShift > 0 and 1 or 0, math.abs(lightShift))

  return newColor
end

local function generateColorsWithShifts(shiftsArray, baseColor)
  local resultColors = {}
  for i, shift in ipairs(shiftsArray) do
    resultColors[i] = adjustColorAttributes(baseColor, shift.hue, shift.sat, shift.bri, shift.shd)
  end
  return resultColors
end

--⁡⁢⁣⁣---------------------------------------⁡--
--            ⁡⁢⁣⁣ 𝘉𝘈𝘛𝘊𝘏 𝘊𝘖𝘓𝘖𝘙𝘚    ⁡          --
--⁡⁢⁣⁣---------------------------------------⁡⁡--

local function computeBaseColorVariants(baseColor)
  basePositiveShadeColors = generateColorsWithShifts(positiveShadeShifts, baseColor)
  baseNegativeShadeColors = generateColorsWithShifts(negativeShadeShifts, baseColor)
  brightnessColors = generateColorsWithShifts(brightnessShifts, baseColor)
  saturationColors = generateColorsWithShifts(saturationShifts, baseColor)
  hueColors = generateColorsWithShifts(hueShifts, baseColor)
end

local function computeHarmonyColorVariants(baseColor)
  local harmonyPositiveShades =  generateColorsWithShifts(positiveShadeShifts, baseColor)
  local harmonyNegativeShades = generateColorsWithShifts(negativeShadeShifts, baseColor)

  return harmonyPositiveShades, harmonyNegativeShades
end

local function refreshHarmonyShades()

  local harmoniesMapping = {
    ["None"] = {},
    ["Complementary"] = {complementaryColor},
    ["Split Complementary"] = splitComplementaryColors,
    ["Triadic"] = triadicColors,
    ["Tetradic"] = tetradicColors,
    ["Square"] = squareColors,
  }

  local selectedHarmony = colorDialog.data.harmonyCombo
  local colors = harmoniesMapping[selectedHarmony]

  harmony1PositiveShadeColors, harmony1NegativeShadeColors = {}, {}
  harmony2PositiveShadeColors, harmony2NegativeShadeColors = {}, {}
  harmony3PositiveShadeColors, harmony3NegativeShadeColors = {}, {}

  for i, color in ipairs(colors) do
      local posShades, negShades = computeHarmonyColorVariants(color)

      if i == 1 then
          harmony1PositiveShadeColors, harmony1NegativeShadeColors = posShades, negShades
      elseif i == 2 then
          harmony2PositiveShadeColors, harmony2NegativeShadeColors = posShades, negShades
      elseif i == 3 then
          harmony3PositiveShadeColors, harmony3NegativeShadeColors = posShades, negShades
      end
  end
end


--⁡⁢⁣⁢---------------------------------------⁡--
--               ⁡⁢⁣⁢𝗜𝗡𝗧𝗘𝗥𝗔𝗖𝗧𝗜𝗢𝗡⁡            --
--⁡⁢⁣⁢---------------------------------------⁡--

local function refreshDialogDisplayData()
  colorDialog:modify{ id="foreground", colors = {foregroundColor} }
  colorDialog:modify{ id="background", colors = {backgroundColor} }
  colorDialog:modify{ id="shadeIntensityFactorSlider", value = shadeIntensityFactor }
  colorDialog:modify{ id="hue", colors = hueColors }
  colorDialog:modify{ id="positiveShading", colors = basePositiveShadeColors }
  colorDialog:modify{ id="negativeShading", colors= baseNegativeShadeColors }
  colorDialog:modify{ id="brightness", colors = brightnessColors }
  colorDialog:modify{ id="saturation", colors = saturationColors }
  colorDialog:modify{ id="harmony1PositiveShading", colors = harmony1PositiveShadeColors }
  colorDialog:modify{ id="harmony1NegativeShading", colors = harmony1NegativeShadeColors }
  colorDialog:modify{ id="harmony2PositiveShading", colors = harmony2PositiveShadeColors }
  colorDialog:modify{ id="harmony2NegativeShading", colors = harmony2NegativeShadeColors }
  colorDialog:modify{ id="harmony3PositiveShading", colors = harmony3PositiveShadeColors }
  colorDialog:modify{ id="harmony3NegativeShading", colors = harmony3NegativeShadeColors }
end


local function onShadeColorClicked(ev)
  useEyeDropper = false;

  if(ev.button == MouseButton.LEFT) then
    app.fgColor = ev.color
  elseif(ev.button == MouseButton.RIGHT) then
    app.bgColor = ev.color
  elseif(ev.button == MouseButton.MIDDLE) then
    app.fgColor = ev.color
    computeBaseColorVariants(app.fgColor)
    refreshHarmonyColors()
    refreshHarmonyShades()
    refreshDialogDisplayData()
  end
end

local function onColorChanged()
  if useEyeDropper and autoUpdateOnPick then
    foregroundColor = app.fgColor
    backgroundColor = app.bgColor

    computeBaseColorVariants(app.fgColor)
    refreshHarmonyColors()
    refreshHarmonyShades()
    refreshDialogDisplayData()
  end
  useEyeDropper = true
end

--⁡⁢⁣⁢---------------------------------------⁡--
--                 ⁡⁢⁣⁢𝗗𝗜𝗔𝗟𝗢𝗚⁡                --
--⁡⁢⁣⁢---------------------------------------⁡--
local function createShadeComponent(id, label, colors)
  return {
      id = id,
      label = label,
      colors = colors,
      onclick = function(ev)
          onShadeColorClicked(ev)
      end
  }
end

local function initializeColorDialog()
  foregroundColor = app.fgColor
  backgroundColor = app.bgColor
  refreshHarmonyColors()
  computeBaseColorVariants(app.fgColor)

  colorDialog = Dialog {
    title = "Easy Shading",
    onclose = function()
      app.events:off(foregroundColorListener)
      app.events:off(backgroundColorListener)
  end
  }

  :shades(createShadeComponent("foreground", "Foreground", {foregroundColor}))
  :shades(createShadeComponent("background", "Background", {backgroundColor}))
  :slider {
      id = "shadeIntensityFactorSlider",
      label = "Shade Intensity",
      min = 1,
      max = 180,
      value = shadeIntensityFactor,
      onchange = function()
          shadeIntensityFactor = colorDialog.data.shadeIntensityFactorSlider
          computeBaseColorVariants(app.fgColor)
          refreshHarmonyColors()
          refreshHarmonyShades()
          refreshDialogDisplayData()
      end
  }
  :button{
      text = "Reset Shade Factor",
      onclick = function()
          shadeIntensityFactor = 50
          colorDialog.data.shadeIntensityFactorSlider = shadeIntensityFactor
          computeBaseColorVariants(app.fgColor)
          refreshHarmonyColors()
          refreshHarmonyShades()
          refreshDialogDisplayData()
      end
  }
  :shades(createShadeComponent("positiveShading", "Positive Shades", basePositiveShadeColors))
  :shades(createShadeComponent("negativeShading", "Negative Shades", baseNegativeShadeColors))
  :shades(createShadeComponent("brightness", "Brightness", brightnessColors))
  :shades(createShadeComponent("saturation", "Saturation", saturationColors))
  :shades(createShadeComponent("hue", "Hue", hueColors))

  :combobox {
      id="harmonyCombo",
      label="Color Harmonies",
      option=availableColorHarmonies[0],
      options=availableColorHarmonies,
      onchange=function(ev)
          foregroundColor = app.fgColor
          backgroundColor = app.bgColor
          computeBaseColorVariants(app.fgColor)
          refreshHarmonyColors()
          refreshHarmonyShades()
          refreshDialogDisplayData()
      end
  }
  :shades(createShadeComponent("harmony1PositiveShading", "Harmony 1 Positive", harmony1PositiveShadeColors))
  :shades(createShadeComponent("harmony1NegativeShading", "Harmony 1 Negative", harmony1NegativeShadeColors))
  :shades(createShadeComponent("harmony2PositiveShading", "Harmony 2 Positive", harmony2PositiveShadeColors))
  :shades(createShadeComponent("harmony2NegativeShading", "Harmony 3 Negative", harmony2NegativeShadeColors))
  :shades(createShadeComponent("harmony3PositiveShading", "Harmony 3 Positive", harmony3PositiveShadeColors))
  :shades(createShadeComponent("harmony3NegativeShading", "Harmony 3 Negative", harmony3NegativeShadeColors))
  colorDialog:show { wait = false }
end

--⁡⁢⁣⁢---------------------------------------⁡--
--                  ⁡⁢⁣⁢𝗥𝗨𝗡⁡                  --
--⁡⁢⁣⁢---------------------------------------⁡--
do
  computeBaseColorVariants(app.fgColor)
  initializeColorDialog();
  foregroundColorListener = app.events:on('fgcolorchange', onColorChanged);
  backgroundColorListener = app.events:on('bgcolorchange', onColorChanged);
end