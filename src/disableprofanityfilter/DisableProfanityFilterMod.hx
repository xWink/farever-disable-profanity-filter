package disableprofanityfilter;

import haxe.Json;
import hlx.runtime.HlxPrefixResult;
import sys.FileSystem;
import sys.io.File;

@:build(hlx.runtime.Mod.build())
class DisableProfanityFilterMod {
    static inline var CONFIG_PATH = "hlx/mods/disable-profanity-filter/config.json";

    static var disableProfanityFilter:Bool = true;

    static var lastConfigModified:Float = -1.0;
    static var configCheckTimer:Float = 0.0;

    static function main():Void {
        loadConfig();
        if (!FileSystem.exists(CONFIG_PATH))
            saveConfig();
    }

    @:hlx.postfix(GameApp.update)
    static function afterGameAppUpdate(instance:Dynamic, dt:Float, result:Void):Void {
        configCheckTimer += dt;
        if (configCheckTimer >= 1.0) {
            configCheckTimer = 0.0;
            reloadConfigIfChanged();
        }
    }

    // Farever's chat messages and speech bubbles pass through cleanPlayerText.
    // Return the original text with the game's HTML escaping still applied, so
    // only profanity replacement is bypassed. Character-name validation uses
    // detectBadWord directly and therefore remains unchanged.
    @:hlx.prefix(HText.cleanPlayerText)
    static function beforeCleanPlayerText(text:String):HlxPrefixResult<String> {
        if (!disableProfanityFilter)
            return Continue;
        return SkipWith(StringTools.htmlEscape(text));
    }

    static function reloadConfigIfChanged():Void {
        try {
            if (!FileSystem.exists(CONFIG_PATH))
                return;
            var modified = FileSystem.stat(CONFIG_PATH).mtime.getTime();
            if (modified != lastConfigModified)
                loadConfig();
        } catch (_:Dynamic) {}
    }

    static function updateConfigModifiedTime():Void {
        try {
            if (FileSystem.exists(CONFIG_PATH))
                lastConfigModified = FileSystem.stat(CONFIG_PATH).mtime.getTime();
        } catch (_:Dynamic) {}
    }

    static function loadConfig():Void {
        try {
            if (!FileSystem.exists(CONFIG_PATH))
                return;

            var data:Dynamic = Json.parse(File.getContent(CONFIG_PATH));
            if (Reflect.hasField(data, "disableProfanityFilter"))
                disableProfanityFilter = Reflect.field(data, "disableProfanityFilter");
        } catch (_:Dynamic) {}
        updateConfigModifiedTime();
    }

    static function saveConfig():Void {
        try {
            var data = {
                disableProfanityFilter: disableProfanityFilter
            };
            File.saveContent(CONFIG_PATH, Json.stringify(data, null, "  "));
            updateConfigModifiedTime();
        } catch (_:Dynamic) {}
    }
}
