package disableprofanityfilter;

import haxe.Json;
import imgui.ImGui;
import imgui.Enums.ImGuiKey;
import imgui.ref.BoolRef;
import hlx.runtime.HlxPrefixResult;
import sys.FileSystem;
import sys.io.File;

@:build(hlx.runtime.Mod.build())
class DisableProfanityFilterMod {
    static inline var CONFIG_PATH = "hlx/mods/disable-profanity-filter/config.json";

    static var disableProfanityFilter = new BoolRef(true);
    static var panelOpen = new BoolRef(true);
    static var hasSeenMenu:Bool = false;

    static var hotkeyKey:Int = ImGuiKey.F9;
    static var hotkeyCtrl:Bool = false;
    static var hotkeyShift:Bool = false;
    static var hotkeyAlt:Bool = false;
    static var hotkeySuper:Bool = false;
    static var capturingHotkey:Bool = false;

    static function main():Void {
        loadConfig();
        panelOpen.set(!hasSeenMenu);
        ImGui.register(HlxRuntime.moduleName(), drawSettings);
    }

    // Farever's chat messages and speech bubbles pass through cleanPlayerText.
    // Return the original text with the game's HTML escaping still applied, so
    // only profanity replacement is bypassed. Character-name validation uses
    // detectBadWord directly and therefore remains unchanged.
    @:hlx.prefix(HText.cleanPlayerText)
    static function beforeCleanPlayerText(text:String):HlxPrefixResult<String> {
        if (!disableProfanityFilter.get())
            return Continue;
        return SkipWith(StringTools.htmlEscape(text));
    }

    static function drawSettings():Void {
        if (!capturingHotkey && hotkeyPressed())
            panelOpen.set(!panelOpen.get());

        if (!panelOpen.get())
            return;

        ImGui.setNextWindowBgAlpha(0.98);
        if (!ImGui.begin("Profanity Filter Settings", panelOpen)) {
            ImGui.end();
            return;
        }

        if (!hasSeenMenu) {
            hasSeenMenu = true;
            saveConfig();
        }

        var oldValue = disableProfanityFilter.get();
        ImGui.checkbox("Disable profanity filter", disableProfanityFilter);
        if (disableProfanityFilter.get() != oldValue)
            saveConfig();

        ImGui.separator();
        ImGui.text("Open settings hotkey: " + hotkeyLabel());
        if (!capturingHotkey) {
            if (ImGui.button("Change hotkey"))
                capturingHotkey = true;
        } else {
            ImGui.text("Press a key combination...");
            ImGui.text("Hold Ctrl/Shift/Alt/Win, then press a key. Esc cancels.");
            captureNextHotkey();
        }

        ImGui.end();
    }

    static function hotkeyPressed():Bool {
        if (!ImGui.isKeyPressed(hotkeyKey, false))
            return false;
        return modifierDown(ImGuiKey.LeftCtrl, ImGuiKey.RightCtrl) == hotkeyCtrl
            && modifierDown(ImGuiKey.LeftShift, ImGuiKey.RightShift) == hotkeyShift
            && modifierDown(ImGuiKey.LeftAlt, ImGuiKey.RightAlt) == hotkeyAlt
            && modifierDown(ImGuiKey.LeftSuper, ImGuiKey.RightSuper) == hotkeySuper;
    }

    static function captureNextHotkey():Void {
        if (ImGui.isKeyPressed(ImGuiKey.Escape, false)) {
            capturingHotkey = false;
            return;
        }

        for (key in 512...632) {
            if (isModifierKey(key) || key == ImGuiKey.Escape)
                continue;
            if (ImGui.isKeyPressed(key, false)) {
                hotkeyKey = key;
                hotkeyCtrl = modifierDown(ImGuiKey.LeftCtrl, ImGuiKey.RightCtrl);
                hotkeyShift = modifierDown(ImGuiKey.LeftShift, ImGuiKey.RightShift);
                hotkeyAlt = modifierDown(ImGuiKey.LeftAlt, ImGuiKey.RightAlt);
                hotkeySuper = modifierDown(ImGuiKey.LeftSuper, ImGuiKey.RightSuper);
                capturingHotkey = false;
                saveConfig();
                return;
            }
        }
    }

    static inline function modifierDown(left:Int, right:Int):Bool {
        return ImGui.isKeyDown(left) || ImGui.isKeyDown(right);
    }

    static inline function isModifierKey(key:Int):Bool {
        return key >= ImGuiKey.LeftCtrl && key <= ImGuiKey.RightSuper;
    }

    static function hotkeyLabel():String {
        var parts = new Array<String>();
        if (hotkeyCtrl) parts.push("Ctrl");
        if (hotkeyShift) parts.push("Shift");
        if (hotkeyAlt) parts.push("Alt");
        if (hotkeySuper) parts.push("Win");
        parts.push(keyLabel(hotkeyKey));
        return parts.join(" + ");
    }

    static function keyLabel(key:Int):String {
        if (key >= ImGuiKey._0 && key <= ImGuiKey._9)
            return String.fromCharCode(48 + (key - ImGuiKey._0));
        if (key >= ImGuiKey.A && key <= ImGuiKey.Z)
            return String.fromCharCode(65 + (key - ImGuiKey.A));
        if (key >= ImGuiKey.F1 && key <= ImGuiKey.F24)
            return "F" + (key - ImGuiKey.F1 + 1);

        return switch (key) {
            case ImGuiKey.Tab: "Tab";
            case ImGuiKey.LeftArrow: "Left";
            case ImGuiKey.RightArrow: "Right";
            case ImGuiKey.UpArrow: "Up";
            case ImGuiKey.DownArrow: "Down";
            case ImGuiKey.PageUp: "Page Up";
            case ImGuiKey.PageDown: "Page Down";
            case ImGuiKey.Home: "Home";
            case ImGuiKey.End: "End";
            case ImGuiKey.Insert: "Insert";
            case ImGuiKey.Delete: "Delete";
            case ImGuiKey.Backspace: "Backspace";
            case ImGuiKey.Space: "Space";
            case ImGuiKey.Enter: "Enter";
            case ImGuiKey.Menu: "Menu";
            default: "Key " + key;
        };
    }

    static function loadConfig():Void {
        try {
            if (!FileSystem.exists(CONFIG_PATH))
                return;

            var data:Dynamic = Json.parse(File.getContent(CONFIG_PATH));
            if (Reflect.hasField(data, "disableProfanityFilter"))
                disableProfanityFilter.set(Reflect.field(data, "disableProfanityFilter"));
            if (Reflect.hasField(data, "hotkeyKey")) {
                hotkeyKey = cast Reflect.field(data, "hotkeyKey");
                if (Reflect.hasField(data, "hotkeyCtrl")) hotkeyCtrl = Reflect.field(data, "hotkeyCtrl");
                if (Reflect.hasField(data, "hotkeyShift")) hotkeyShift = Reflect.field(data, "hotkeyShift");
                if (Reflect.hasField(data, "hotkeyAlt")) hotkeyAlt = Reflect.field(data, "hotkeyAlt");
                if (Reflect.hasField(data, "hotkeySuper")) hotkeySuper = Reflect.field(data, "hotkeySuper");
            }
            if (Reflect.hasField(data, "hasSeenMenu"))
                hasSeenMenu = Reflect.field(data, "hasSeenMenu");
            else
                hasSeenMenu = true;
        } catch (_:Dynamic) {}
    }

    static function saveConfig():Void {
        try {
            var data = {
                disableProfanityFilter: disableProfanityFilter.get(),
                hotkeyKey: hotkeyKey,
                hotkeyCtrl: hotkeyCtrl,
                hotkeyShift: hotkeyShift,
                hotkeyAlt: hotkeyAlt,
                hotkeySuper: hotkeySuper,
                hasSeenMenu: hasSeenMenu
            };
            File.saveContent(CONFIG_PATH, Json.stringify(data, null, "  "));
        } catch (_:Dynamic) {}
    }
}
