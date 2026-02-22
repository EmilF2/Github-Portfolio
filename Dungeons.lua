local rs = game:GetService("ReplicatedStorage")

local module = {}

module.drops = {
	coins = {
		stat = "leaderstats",
		name = "Coins",
		display = "Coins",
		icon = "rbxassetid://83801810914654",
	},
	
	luckPotion30m = {
		stat = "Potions",
		name = "LuckBoost30m",
		display = "Luck Boost I",
		icon = "rbxassetid://127337967253469",
	},
	
	luckPotion90m = {
		stat = "Potions",
		name = "LuckBoost90m",
		display = "Luck Boost II",
		icon = "rbxassetid://77140256616008",
	},
	
	quickRollPotion30m = {
		stat = "Potions",
		name = "RollSpeedBoost30m",
		display = "Roll Speed Boost I",
		icon = "rbxassetid://131048594753325",
	},
	
	quickRollPotion90m = {
		stat = "Potions",
		name = "RollSpeedBoost90m",
		display = "Roll Speed Boost II",
		icon = "rbxassetid://125187819819176",
	},
}

module.enemys = {
	NPC = {
		rig = rs.NPCs.NPC,
		baseHealth = 100,
		baseDamage = 10
	},
	
	Zombie = {
		rig = rs.NPCs.Zombie,
		baseHealth = 175,
		baseDamage = 20
	},
	
	Pirate = {
		rig = rs.NPCs.Pirate,
		baseHealth = 225,
		baseDamage = 25
	},
	
	["Fast Zombie"] = {
		rig = rs.NPCs["Fast Zombie"],
		baseHealth = 100,
		baseDamage = 25
	},
	
	["Strong Pirate"] = {
		rig = rs.NPCs["Strong Pirate"],
		baseHealth = 300,
		baseDamage = 50
	},
	
	["NPC Boss"] = {
		rig = rs.NPCs["NPC Boss"],
		baseHealth = 1000,
		baseDamage = 25
	},
	
	["Zombie Boss"] = {
		rig = rs.NPCs["Zombie Boss"],
		baseHealth = 2500,
		baseDamage = 50
	},
	
	["Pirate Boss"] = {
		rig = rs.NPCs["Pirate Boss"],
		baseHealth = 4000,
		baseDamage = 100
	},
}

module.locations = {
	gasStation = {
		map = workspace.Maps["Gas Station"],
		spawns = {
			[1] = workspace.Maps["Gas Station"]:WaitForChild("Spawn1"),
			[2] = workspace.Maps["Gas Station"]:WaitForChild("Spawn2")
		}
	},
	
	desert = {
		map = workspace.Maps["Desert"],
		spawns = {
			[1] = workspace.Maps["Desert"]:WaitForChild("Spawn1"),
		}
	},
	
	frozenSea = {
		map = workspace.Maps["Frozen Sea"],
		spawns = {
			[1] = workspace.Maps["Frozen Sea"]:WaitForChild("Spawn1"),
		}
	},
}

module.dungeons = {
	[1] = {
		location = module.locations.gasStation,
		dropAmount = 2,
		
		drops = {
			[1] = {
				amount = 100,
				chance = 99,
				stat = module.drops.coins
			},
			
			[2] = {
				amount = 1,
				chance = 1,
				stat = module.drops.quickRollPotion30m
			},
		},
		
		waves = {
			[1] = {
				NPC = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},
			},
		}
	},
	
	[2] = {
		location = module.locations.gasStation,
		dropAmount = 3,

		drops = {
			[1] = {
				amount = 250,
				chance = 98,
				stat = module.drops.coins
			},

			[2] = {
				amount = 1,
				chance = 2,
				stat = module.drops.luckPotion30m
			},
		},

		waves = {
			[1] = {
				NPC = {
					healthMultiplier = 1.5,
					damageMultiplier = 1.5,
					amount = 2
				},
			},

			[2] = {
				NPC = {
					healthMultiplier = 1.5,
					damageMultiplier = 2,
					amount = 3
				},
			},
		}
	},
	
	[3] = {
		location = module.locations.gasStation,
		dropAmount = 5,

		drops = {
			[1] = {
				amount = 1000,
				chance = 99,
				stat = module.drops.coins
			},

			[2] = {
				amount = 1,
				chance = 1,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				NPC = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 5
				},
			},

			[2] = {
				NPC = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 4
				},
			},
			
			[3] = {
				["NPC Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 1
				},
			},
		}
	},
	
	[4] = {
		location = module.locations.gasStation,
		dropAmount = 5,

		drops = {
			[1] = {
				amount = 5000,
				chance = 95,
				stat = module.drops.coins
			},

			[2] = {
				amount = 1,
				chance = 5,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				["NPC Boss"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 1
				},
			},

			[2] = {
				["NPC Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 1
				},
			},
		}
	},
	
	[5] = {
		location = module.locations.gasStation,
		dropAmount = 5,

		drops = {
			[1] = {
				amount = 10000,
				chance = 97,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 3,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				["NPC Boss"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 1
				},
			},

			[2] = {
				["NPC Boss"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 1
				},
			},
		}
	},
	
	[6] = {
		location = module.locations.desert,
		dropAmount = 2,

		drops = {
			[1] = {
				amount = 500,
				chance = 97,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 3,
				stat = module.drops.quickRollPotion30m
			},
		},

		waves = {
			[1] = {
				Zombie = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},
			},
		}
	},
	
	[7] = {
		location = module.locations.desert,
		dropAmount = 3,

		drops = {
			[1] = {
				amount = 1250,
				chance = 95,
				stat = module.drops.coins
			},

			[2] = {
				amount = 1,
				chance = 5,
				stat = module.drops.luckPotion30m
			},
		},

		waves = {
			[1] = {
				Zombie = {
					healthMultiplier = 3,
					damageMultiplier = 1.8,
					amount = 2
				},
			},

			[2] = {
				Zombie = {
					healthMultiplier = 2.5,
					damageMultiplier = 2,
					amount = 3
				},
				
				["Fast Zombie"] = {
					healthMultiplier = 1.5,
					damageMultiplier = 2,
					amount = 1
				}
			},
			
		}
	},
	
	[8] = {
		location = module.locations.desert,
		dropAmount = 3,

		drops = {
			[1] = {
				amount = 5000,
				chance = 90,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 10,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				Zombie = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 5
				},
			},

			[2] = {
				Zombie = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 2
				},
				
				["Fast Zombie"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 1
				}
			},

			[3] = {
				["Zombie Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 1
				},
				
				["Fast Zombie"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 1
				}
			},
		}
	},
	
	[9] = {
		location = module.locations.desert,
		dropAmount = 5,

		drops = {
			[1] = {
				amount = 7000,
				chance = 90,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 20,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				["Fast Zombie"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 3
				},
			},

			[2] = {
				Zombie = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 2
				},

				["Fast Zombie"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 1
				}
			},

			[3] = {
				["Zombie Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},

				["Fast Zombie"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 2
				}
			},
		}
	},
	
	[10] = {
		location = module.locations.frozenSea,
		dropAmount = 2,

		drops = {
			[1] = {
				amount = 1000,
				chance = 96,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 4,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				Pirate = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},
			},
		}
	},

	[11] = {
		location = module.locations.frozenSea,
		dropAmount = 3,

		drops = {
			[1] = {
				amount = 1750,
				chance = 93,
				stat = module.drops.coins
			},

			[2] = {
				amount = 3,
				chance = 7,
				stat = module.drops.quickRollPotion30m
			},
		},

		waves = {
			[1] = {
				Pirate = {
					healthMultiplier = 2,
					damageMultiplier = 1.8,
					amount = 2
				},
			},

			[2] = {
				Pirate = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 3
				},

				["Strong Pirate"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 1
				}
			},

		}
	},

	[12] = {
		location = module.locations.frozenSea,
		dropAmount = 3,

		drops = {
			[1] = {
				amount = 10000,
				chance = 80,
				stat = module.drops.coins
			},

			[2] = {
				amount = 3,
				chance = 20,
				stat = module.drops.quickRollPotion90m
			},
		},

		waves = {
			[1] = {
				Pirate = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 2
				},
			},

			[2] = {
				Pirate = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 2
				},

				["Strong Pirate"] = {
					healthMultiplier = 1.2,
					damageMultiplier = 1.2,
					amount = 1
				}
			},

			[3] = {
				["Pirate Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 1
				},

				["Strong Pirate"] = {
					healthMultiplier = 1.2,
					damageMultiplier = 1.2,
					amount = 1
				}
			},
		}
	},
	
	[13] = {
		location = module.locations.frozenSea,
		dropAmount = 5,

		drops = {
			[1] = {
				amount = 15000,
				chance = 80,
				stat = module.drops.coins
			},

			[2] = {
				amount = 3,
				chance = 20,
				stat = module.drops.quickRollPotion90m
			},
		},

		waves = {
			[1] = {
				["Strong Pirate"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 3
				},
			},

			[2] = {
				Pirate = {
					healthMultiplier = 1.8,
					damageMultiplier = 2,
					amount = 2
				},

				["Strong Pirate"] = {
					healthMultiplier = 1.2,
					damageMultiplier = 1.2,
					amount = 3
				}
			},

			[3] = {
				["Pirate Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},

				["Strong Pirate"] = {
					healthMultiplier = 1.2,
					damageMultiplier = 1.2,
					amount = 2
				}
			},
		}
	},
	
	[14] = {
		location = module.locations.frozenSea,
		dropAmount = 2,

		drops = {
			[1] = {
				amount = 50000,
				chance = 50,
				stat = module.drops.coins
			},

			[2] = {
				amount = 3,
				chance = 50,
				stat = module.drops.quickRollPotion90m
			},
		},

		waves = {
			[1] = {
				["Strong Pirate"] = {
					healthMultiplier = 1.8,
					damageMultiplier = 1.5,
					amount = 5
				},
			},

			[2] = {
				Pirate = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 2
				},

				["Strong Pirate"] = {
					healthMultiplier = 1.5,
					damageMultiplier = 1.5,
					amount = 3
				}
			},

			[3] = {
				["Pirate Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 4
				},
			},
		}
	},
	
	[15] = {
		location = module.locations.frozenSea,
		dropAmount = 10,

		drops = {
			[1] = {
				amount = 20000,
				chance = 80,
				stat = module.drops.coins
			},

			[2] = {
				amount = 2,
				chance = 20,
				stat = module.drops.luckPotion90m
			},
		},

		waves = {
			[1] = {
				["Strong Pirate"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 5
				},
			},

			[2] = {
				["Strong Pirate"] = {
					healthMultiplier = 1.2,
					damageMultiplier = 1.2,
					amount = 3
				},
				
				["Pirate Boss"] = {
					healthMultiplier = 1,
					damageMultiplier = 1,
					amount = 2
				},
			},

			[3] = {
				["Pirate Boss"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 2
				},

				["Strong Pirate"] = {
					healthMultiplier = 2,
					damageMultiplier = 2,
					amount = 2
				}
			},
		}
	},
}

return module
