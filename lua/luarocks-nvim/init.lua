local paths = require("luarocks-nvim.paths")
local rocks = require("luarocks-nvim.rocks")
local build = require("luarocks-nvim.build")
local notify = require("luarocks-nvim.notify")

return {
	setup = function(opts)
		opts = opts or {}

		-- Register an install command
		vim.api.nvim_create_user_command("RocksInstall", function(o)
			rocks.install(o.fargs)
		end, { nargs = "+" })

		-- Make lua scripts available
		package.path = package.path .. ";" .. table.concat(paths.share, ";")
		-- Make .so files available
		package.cpath = package.cpath .. ";" .. paths.lib

		-- Make treesitter parsers available
		vim.opt.rtp:append(paths.rtp_lib)

		-- Check that the system is ready to install rocks
		if build.is_prepared() then
			-- Invoke the luarocks loader. This allows many versions of the same
			-- dependency to exist within the Lua environment.
			--
			-- See https://github.com/luarocks/luarocks/wiki/Using-LuaRocks#multiple-versions-using-the-luarocks-package-loader for details.
			local ok, err = pcall(require, "luarocks.loader")

			if not ok then
				notify.error(
					string.format(
						"Unable to load the luarocks package loader. Try re-running the build stage (`:Lazy build luarocks.nvim`). Full trace: %s",
						err
					)
				)
			end

			-- We have requested rocks so ensure they are installed
			rocks.ensure(opts.rocks)
		else
			-- We haven't built yet so register the rocks
			-- to be installed after build finishes
			build.ensure_rocks_after_build(opts.rocks, opts.luarocks_build_args)
			if opts.auto_install then
				build.build()
			end
		end
	end,
}
