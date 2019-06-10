
local gbc = cc.import("#gbc")
local SensitiveAction = cc.class("SensitiveAction", gbc.ActionBase)
local sensitive = cc.import("#sensitive")
local sensitive_library = sensitive.library

function SensitiveAction:checkAction(args)
    if args.name then
        return {
            result = sensitive_library:check(args.name),
            name = args.name,
        }
    end
end

function SensitiveAction:replaceAction(args)
    if args.name then
        return sensitive_library:replace(args.name)
    end
end

return SensitiveAction
