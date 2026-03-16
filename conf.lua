if arg[2] == "debug" then
    require("lldebugger").start()
    function love.errorhandler(msg)
		error(msg, 2)
	end
end

function love.conf(t)
    t.window.vsync = 0
end