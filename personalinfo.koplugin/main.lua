local WidgetContainer = require("ui/widget/container/widgetcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local TextBoxWidget = require("ui/widget/textboxwidget")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local LuaSettings = require("luasettings")
local DataStorage = require("datastorage")
local Geom = require("ui/geometry")
local Font = require("ui/font")
local Screen = require("device").screen

local WIDGET_ID = "personalinfo.contact"
local SETTINGS_PATH = DataStorage:getSettingsDir() .. "/personalinfo.lua"
local DEFAULT_PROMPT = "Se encontrar este dispositivo, contate:"

local DEFAULT_STYLE = {
    name = { font_face = "default", font_size = 22, bold = true },
    details = { font_face = "default", font_size = 15, bold = false },
}

local PersonalInfo = WidgetContainer:extend{
    name = "personalinfo",
    is_doc_only = false,
}

local function read_text(settings, key, fallback)
    local value = settings:readSetting(key)
    if type(value) == "string" then return value end
    return fallback or ""
end

local function read_boolean(settings, key, default)
    local value = settings:readSetting(key)
    return type(value) == "boolean" and value or default
end

local function read_number(settings, key, default, minimum, maximum)
    local value = tonumber(settings:readSetting(key)) or default
    return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
end

local function trim(text)
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function style_for(settings, key)
    local defaults = DEFAULT_STYLE[key]
    return {
        font_face = read_text(settings, key .. "_font_face", defaults.font_face),
        font_size = read_number(settings, key .. "_font_size", defaults.font_size, 6, 48),
        bold = read_boolean(settings, key .. "_bold", defaults.bold),
    }
end

local function font_face_for(style, px)
    -- Use the same font resolver as the native ZenOS Home widgets when possible.
    local ok, library_font = pcall(require, "modules/filebrowser/patches/library_font")
    if ok and library_font and type(library_font.getStyleFace) == "function" then
        return library_font.getStyleFace(style.font_face, px)
    end
    local file = style.font_face ~= "default" and style.font_face or "cfont"
    local ok_font, face = pcall(Font.getFace, Font, file, px)
    if ok_font and face then return face end
    return Font:getFace("cfont", px)
end

local function build_widget(settings, ctx)
    local name = trim(read_text(settings, "name"))
    local email = trim(read_text(settings, "email"))
    local phone = trim(read_text(settings, "phone"))
    local prompt = trim(read_text(settings, "prompt", DEFAULT_PROMPT))
    local show_prompt = read_boolean(settings, "show_prompt", true)
    local alignment = read_text(settings, "alignment", "center")
    if alignment ~= "left" and alignment ~= "right" then alignment = "center" end

    local name_style = style_for(settings, "name")
    local details_style = style_for(settings, "details")
    local has_contact = email ~= "" or phone ~= ""
    local width = math.max(1, tonumber(ctx.width) or Screen:getWidth())
    local height = math.max(1, tonumber(ctx.height) or Screen:getHeight())
    local padding = Screen:scaleBySize(12)
    local text_width = math.max(1, width - padding * 2)

    local function layout(scale)
        local children = { align = "center" }
        local function add(text, style)
            local px = Screen:scaleBySize(math.max(6, math.floor(style.font_size * scale + 0.5)))
            children[#children + 1] = TextBoxWidget:new{
                text = text,
                face = font_face_for(style, px),
                bold = style.bold,
                width = text_width,
                alignment = alignment,
            }
        end
        local function gap(n)
            children[#children + 1] = VerticalSpan:new{
                width = math.max(1, Screen:scaleBySize(math.floor(n * scale + 0.5))),
            }
        end

        if name == "" and not has_contact then
            add("Configure este widget em Zen Settings > Home > Widgets", details_style)
        else
            if name ~= "" then add(name, name_style) end
            if has_contact then
                if name ~= "" then gap(8) end
                if show_prompt and prompt ~= "" then
                    add(prompt, details_style)
                    gap(3)
                end
                if email ~= "" then add(email, details_style) end
                if email ~= "" and phone ~= "" then gap(2) end
                if phone ~= "" then add(phone, details_style) end
            end
        end
        return VerticalGroup:new(children)
    end

    -- Keep the chosen font sizes when possible; shrink on crowded layouts.
    local content
    local scale = 1
    for _i = 1, 10 do
        content = layout(scale)
        if content:getSize().h <= height - padding * 2 or scale <= 0.55 then
            break
        end
        content:free()
        content = nil
        scale = scale - 0.05
    end

    return CenterContainer:new{
        dimen = Geom:new{ w = width, h = height },
        content,
    }
end

function PersonalInfo:registerWidget()
    if not self.settings then return end
    local register = rawget(_G, "__ZENOS_REGISTER_HOME_ITEM")
    if type(register) ~= "function" then return end
    local settings = self.settings
    register(WIDGET_ID, function(ctx)
        return build_widget(settings, ctx)
    end, { label = "Informações pessoais", size = "m" })
end

function PersonalInfo:saveSetting(key, value, menu)
    self.settings:saveSetting(key, value)
    self.settings:flush()
    self:registerWidget() -- Requests a ZenOS Home rebuild, even when Home is hidden.
    if menu and type(menu.updateItems) == "function" then menu:updateItems() end
end

function PersonalInfo:editField(key, title, menu)
    local dialog
    dialog = InputDialog:new{
        title = title,
        input = read_text(self.settings, key, key == "prompt" and DEFAULT_PROMPT or ""),
        input_type = "text",
        buttons = {
            {
                {
                    text = "Cancelar",
                    id = "close",
                    callback = function() UIManager:close(dialog) end,
                },
                {
                    text = "Salvar",
                    is_enter_default = true,
                    callback = function()
                        local value = dialog:getInputText() or ""
                        UIManager:close(dialog)
                        self:saveSetting(key, value, menu)
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

local function font_label(font_face)
    if font_face == "default" then return "Padrão do ZenOS" end
    return font_face:match("([^/\\]+)$") or font_face
end

function PersonalInfo:styleItems(group, title)
    local defaults = DEFAULT_STYLE[group]
    local function style() return style_for(self.settings, group) end
    return {
        {
            text_func = function()
                return "Fonte: " .. font_label(style().font_face)
            end,
            keep_menu_open = true,
            callback = function(menu)
                local ok, FontChooser = pcall(require, "ui/widget/fontchooser")
                if not ok then return end
                local current = style().font_face
                local base = Font:getFace("cfont", Screen:scaleBySize(16))
                local default_font = base and base.orig_font or "NotoSans-Regular.ttf"
                local ok_library, library_font = pcall(require,
                    "modules/filebrowser/patches/library_font")
                if ok_library and library_font and library_font.getFontName then
                    default_font = library_font.getFontName()
                end
                UIManager:show(FontChooser:new{
                    title = title .. " - Fonte",
                    font_file = current == "default" and default_font or current,
                    default_font_file = default_font,
                    callback = function(file)
                        if type(file) == "string" and file ~= "" then
                            self:saveSetting(group .. "_font_face", file, menu)
                        end
                    end,
                })
            end,
            hold_callback = function(menu)
                self:saveSetting(group .. "_font_face", "default", menu)
            end,
        },
        {
            text_func = function()
                return "Tamanho da fonte: " .. tostring(style().font_size)
            end,
            keep_menu_open = true,
            callback = function(menu)
                local SpinWidget = require("ui/widget/spinwidget")
                UIManager:show(SpinWidget:new{
                    title_text = title .. " - Tamanho da fonte",
                    value = style().font_size,
                    value_min = 6,
                    value_max = 48,
                    default_value = defaults.font_size,
                    callback = function(spin)
                        self:saveSetting(group .. "_font_size", spin.value, menu)
                    end,
                })
            end,
        },
        {
            text = "Negrito",
            checked_func = function() return style().bold end,
            callback = function(menu)
                self:saveSetting(group .. "_bold", not style().bold, menu)
            end,
        },
        {
            text = "Restaurar estilo padrão",
            callback = function(menu)
                for k, v in pairs(defaults) do
                    self.settings:saveSetting(group .. "_" .. k, v)
                end
                self.settings:flush()
                self:registerWidget()
                if menu and menu.updateItems then menu:updateItems() end
            end,
        },
    }
end

function PersonalInfo:settingsItems()
    local function field_item(key, label)
        return {
            text_func = function()
                local value = trim(read_text(self.settings, key))
                if value == "" then value = "(não preenchido)" end
                if #value > 35 then value = value:sub(1, 32) .. "..." end
                return label .. ": " .. value
            end,
            keep_menu_open = true,
            callback = function(menu) self:editField(key, label, menu) end,
        }
    end
    return {
        field_item("name", "Nome"),
        field_item("email", "E-mail"),
        field_item("phone", "Telefone"),
        {
            text = "Mensagem de recuperação",
            sub_item_table = {
                {
                    text = "Exibir mensagem",
                    checked_func = function()
                        return read_boolean(self.settings, "show_prompt", true)
                    end,
                    callback = function(menu)
                        local next_value = not read_boolean(self.settings, "show_prompt", true)
                        self:saveSetting("show_prompt", next_value, menu)
                    end,
                },
                field_item("prompt", "Texto"),
            },
        },
        {
            text = "Estilo do nome",
            sub_item_table_func = function()
                return self:styleItems("name", "Nome")
            end,
        },
        {
            text = "Estilo do contato",
            sub_item_table_func = function()
                return self:styleItems("details", "Contato")
            end,
        },
        {
            text = "Alinhamento",
            sub_item_table = (function()
                local items = {}
                for _, entry in ipairs({
                    { key = "left", label = "Esquerda" },
                    { key = "center", label = "Centro" },
                    { key = "right", label = "Direita" },
                }) do
                    local key = entry.key
                    items[#items + 1] = {
                        text = entry.label,
                        radio = true,
                        checked_func = function()
                            return read_text(self.settings, "alignment", "center") == key
                        end,
                        callback = function(menu)
                            self:saveSetting("alignment", key, menu)
                        end,
                    }
                end
                return items
            end)(),
        },
    }
end

function PersonalInfo:openWidgetSettings(zen_plugin)
    local ok, ArrangeList = pcall(require, "common/ui/zen_arrange_list")
    if not ok or not ArrangeList then return false end
    ArrangeList.show{
        title = "Informações pessoais",
        item_table = self:settingsItems(),
        plugin = zen_plugin or rawget(_G, "__ZEN_UI_PLUGIN"),
        allow_arrange = false,
        hide_footer_cancel = true,
    }
    return true
end

function PersonalInfo:installZenSettingsHooks()
    if not self.settings then return end
    if type(rawget(_G, "__ZENOS_REGISTER_HOME_ITEM")) ~= "function" then return end

    local ok_home, HomeSettings = pcall(require,
        "modules/settings/sections/library_settings/home_settings")
    if ok_home and HomeSettings and type(HomeSettings.openWidgetSettings) == "function" then
        if not self._home_settings_hook or self._home_settings_hook.module ~= HomeSettings then
            local old = HomeSettings.openWidgetSettings
            local owner = self
            local patched = function(id, zen_plugin)
                if id == WIDGET_ID then return owner:openWidgetSettings(zen_plugin) end
                return old(id, zen_plugin)
            end
            HomeSettings.openWidgetSettings = patched
            self._home_settings_hook = { module = HomeSettings, original = old, patched = patched }
        end
    end

    local ok_arrange, ArrangeList = pcall(require, "common/ui/zen_arrange_list")
    if ok_arrange and ArrangeList and type(ArrangeList.show) == "function" then
        if not self._arrange_hook or self._arrange_hook.module ~= ArrangeList then
            local old = ArrangeList.show
            local owner = self
            local patched = function(opts)
                if type(opts) == "table" and type(opts.item_table) == "table" then
                    for _, item in ipairs(opts.item_table) do
                        if item.orig_item == WIDGET_ID then
                            -- ZenOS 4.3.1 gives settings submenus only to built-in widget IDs.
                            -- Add the same submenu to our own row without changing ZenOS files.
                            item.sub_title = "Informações pessoais"
                            item.sub_item_table_func = function()
                                return owner:settingsItems()
                            end
                        end
                    end
                end
                return old(opts)
            end
            ArrangeList.show = patched
            self._arrange_hook = { module = ArrangeList, original = old, patched = patched }
        end
    end
end

function PersonalInfo:init()
    -- The Home widget belongs to FileManager; avoid competing Reader instances.
    if self.ui.document then return end
    self.settings = LuaSettings:open(SETTINGS_PATH)
    self:registerWidget()
    self:installZenSettingsHooks()
    -- Retain a KOReader-menu fallback where the standard menu is available.
    if self.ui.menu then self.ui.menu:registerToMainMenu(self) end
end

function PersonalInfo:onZenOSReady()
    if not self.settings then return end
    self:registerWidget()
    self:installZenSettingsHooks()
end

function PersonalInfo:addToMainMenu(menu_items)
    menu_items.personalinfo = {
        text = "Informações pessoais",
        callback = function() self:openWidgetSettings() end,
    }
end

function PersonalInfo:onCloseWidget()
    if not self.settings then return end
    for _, hook in ipairs({ self._arrange_hook, self._home_settings_hook }) do
        if hook and hook.module and hook.module.show == hook.patched then
            hook.module.show = hook.original
        elseif hook and hook.module and hook.module.openWidgetSettings == hook.patched then
            hook.module.openWidgetSettings = hook.original
        end
    end
    local unregister = rawget(_G, "__ZENOS_UNREGISTER_HOME_ITEM")
    if type(unregister) == "function" then unregister(WIDGET_ID) end
end

return PersonalInfo
