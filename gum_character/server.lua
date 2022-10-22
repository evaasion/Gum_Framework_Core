gumCore = {}

TriggerEvent("getCore",function(core)
	gumCore = core
end)
Inventory = exports.gum_inventory:gum_inventoryApi()
inv = exports.gum_inventory:gum_inventoryApi()

function contains(table, element)
	if table ~= 0 then
		for k, v in pairs(table) do
			if v == element then
				return true
			end
		end
	end
return false
end

function keysx(table)
	local keys = 0
	for k, v in pairs(table) do
		keys = keys + 1
	end
	return keys
end 

RegisterServerEvent('gum_character:check_character')
AddEventHandler('gum_character:check_character', function()
	local _source = source
	local User = gumCore.getUser(_source)
	if User ~= nil then
		local Character = User.getUsedCharacter
		local identifier = GetPlayerIdentifier(tonumber(_source))
		if Character ~= nil then
			exports.ghmattimysql:execute('SELECT * FROM characters WHERE identifier = @identifier' , {['identifier'] = identifier}, function(result)
				if result[1] ~= nil then
					TriggerClientEvent("gum_character:check_char", _source, true)
					TriggerClientEvent("gum_character:select_char", tonumber(_source), result, User)
				end
			end)
		else
			TriggerClientEvent("gum_character:check_char", _source, false)
		end
	else
		TriggerClientEvent("gum_character:check_char", _source, false)
	end
end)


RegisterServerEvent('gum_character:select_char')
AddEventHandler('gum_character:select_char', function(charid, skin_table, outfit_table, coords, is_dead)
	local _source = source
	local User = gumCore.getUser(tonumber(_source))
	TriggerClientEvent("gum_character:send_data_back", tonumber(_source), skin_table, outfit_table, coords, is_dead, true)
	TriggerClientEvent("gum_clothes:send_outfit", tonumber(_source), skin_table, outfit_table)
	User.setUsedCharacter(tonumber(_source), charid)
end)

RegisterServerEvent('gum_character:check_character2')
AddEventHandler('gum_character:check_character2', function()
	local _source = source
	local User = gumCore.getUser(source)
	local Character = User.getUsedCharacter
	local identifier = GetPlayerIdentifier(source)
	exports.ghmattimysql:execute('SELECT firstname FROM characters WHERE identifier = @identifier' , {['identifier'] = identifier}, function(result)
		if result[1] ~= nil then
            TriggerClientEvent("gum_character:check_char", _source, true)
			exports.ghmattimysql:execute('SELECT skinPlayer,compPlayer,coords,charidentifier,isdead FROM characters WHERE identifier = @identifier' , {['identifier'] = identifier}, function(result)
				if result[1] ~= nil then
					local skin_table = {}
					local skin_table = json.decode(result[1].skinPlayer)
					local outfit_table = {}
					local outfit_table = json.decode(result[1].compPlayer)
					local coords_saved = {}
					local coords_saved = json.decode(result[1].coords)
					local is_dead = result[1].isdead
					local charid = result[1].charidentifier
					TriggerClientEvent("gum_character:send_data_back", _source, skin_table, outfit_table, coords_saved, is_dead)
					TriggerClientEvent("gum_clothes:send_outfit", _source, skin_table, outfit_table)
				end
			end)
			-- exports.ghmattimysql:execute('SELECT title,comps FROM outfits WHERE identifier = @identifier' , {['identifier'] = identifier}, function(result)
			-- 	if result ~= nil then
			-- 		TriggerClientEvent("gum_clothes:save_outfits", tonumber(_source), result)
			-- 	end
			-- end)
        else
            TriggerClientEvent("gum_character:check_char", _source, false)
		end
	end)
end)


RegisterServerEvent('gum_character:save_character')
AddEventHandler( 'gum_character:save_character', function(firstname, lastname, skin_table, clothetable, coords_table_save)
	local _source = source
	gumCore.addCharacter(_source, firstname, lastname, json.encode(skin_table), json.encode(clothetable))
	Citizen.Wait(2000)
	TriggerClientEvent("gum_character:send_character", _source)
end)


RegisterServerEvent('gum_character:dead_state')
AddEventHandler( 'gum_character:dead_state', function(state)
	local _source = source
	local User = gumCore.getUser(source)
	local char = User.getUsedCharacter
	local identifier = char.identifier
	local Character = User.getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local u_inventory = Character.inventory
	local money = char.money
	local gold = char.gold
	local role = char.rol
	local tableofstuff = {}

	if state == false then
		isDead = 0
	else
		isDead = 1
		if Config.removeweapons then
			exports.ghmattimysql:execute('SELECT id,identifier,name FROM loadout WHERE charidentifier = @charidentifier AND identifier = @identifier' , {['identifier'] = u_identifier, ['charidentifier'] = u_charid}, function(result)
				for k, v in pairs (result) do
					if not contains(Config.blacklistedweapons, v.name) then
						local id = v.id
						print(id)
						inv.subWeapon(_source, v.id)
						exports.ghmattimysql:execute("DELETE FROM loadout WHERE id=@id", { ['id'] = id})
					end
				end
			end)
		end
		if Config.removeitems then
			TriggerEvent("gumCore:getUserInventory", _source, function(getInventory)
				for k, v in pairs (getInventory) do
					if not contains(Config.blacklisteditems,v.item) then
						table.insert(tableofstuff,{item = v.item, count= v.count})
						inv.subItem(_source, v.item, v.count)
					end
				end
			end)
		end
	end
	if Config.removecash then
		if money > 0 then
			table.insert(tableofstuff, {cash = money})
			char.removeCurrency(_source, 0, money)
		end
	end
	if Config.removegold then
		if gold > 0 then
			table.insert(tableofstuff, {gold = gold})
			char.removeCurrency(1, gold)
		end
	end


	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['isdead'] = isDead }
	exports.ghmattimysql:execute("UPDATE characters SET isdead = @isdead WHERE identifier = @identifier AND charidentifier = @charidentifier", Parameters)
	TriggerClientEvent("gum_notify:notify", _source, "COMA", "Tu es dans le coma, tu as perdu tes objets et armes", "COMA", 5000)


end)

function DiscordWeb(color, name, footer)
    local embed = {
        {
            ["color"] = color,
            ["title"] = "",
            ["description"] = "".. name .."",
            ["footer"] = {
                ["text"] = footer,
            },
        }
    }
    PerformHttpRequest('https://discord.com/api/webhooks/885079025142341643/7UvTqB5xav0jZB6icdEO5ZZBvzERNnsom0nv5Cq8GD-zxhZbcf3wWogqHbVHADON0oKv', function(err, text, headers) end, 'POST', json.encode({username = "RedwestRP", embeds = embed}), { ['Content-Type'] = 'application/json' })
end
