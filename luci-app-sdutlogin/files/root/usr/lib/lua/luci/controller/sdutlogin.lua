-- Copyright 2020 BlackYau <blackyau426@gmail.com>
-- GNU General Public License v3.0


module("luci.controller.sdutlogin", package.seeall)

function index()
        entry({"admin", "network", "sdutlogin"},firstchild(), _("SDUT Login"), 100).dependent = false
        entry({"admin", "network", "sdutlogin", "general"}, cbi("sdutlogin"), _("Base Setting"), 1)
        entry({"admin", "network", "sdutlogin", "log"}, form("sdutloginlog"), _("Log"), 2)
        end