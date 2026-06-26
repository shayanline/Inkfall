class_name DemoStory
extends RefCounted
## Pure-data prototype story. One title, two acts, scripted lines with fx events. This is just
## scaffolding to prove the look and flow, the real writing comes later. All acts use the one
## flexible NoirPanel, configured by data.


static func get_story() -> Dictionary:
	return {
		"title": "NOIR",
		"subtitle": "A WORKING TITLE",
		"blurb": "A rain-soaked city where the only colour is the colour that bleeds.",
		"music": "burning_silence",
		"music_vol": 0.5,
		"scenes": [
			{
				"title": "THE STREET",
				"panel": "res://scenes/panels/NoirPanel.tscn",
				"ambience": "street",
				"indoor": false,
				"rain_vol": 0.18,
				"config": {
					"seed": 7,
					"ground": 0.8,
					"moon": true,
					"lamp": true,
					"lamp_x": 0.28,
					"figure_x": 0.5,
					"red_accent": true,
					"neon": {"x": 0.7, "y": 0.4, "color": Color("e10010")},
				},
				"script": [
					{"text": "Rain again. The city only ever cries at night."},
					{"text": "She came in out of the wet, trouble in a red coat.", "fx": ["lighter"]},
					{"text": "A flash lit the alley white.", "fx": ["lightning"]},
					{"text": "Then the shot. <b>One</b>. That was all it took.", "fx": ["muzzle", "blood"]},
				],
			},
			{
				"title": "THE ROOFTOP",
				"panel": "res://scenes/panels/NoirPanel.tscn",
				"ambience": "rooftop",
				"indoor": false,
				"rain_vol": 0.14,
				"config": {
					"seed": 19,
					"ground": 0.78,
					"moon": true,
					"lamp": false,
					"searchlight": true,
					"figure_x": 0.6,
					"red_accent": true,
					"neon": {"x": 0.32, "y": 0.5, "color": Color("2bd6ff")},
				},
				"script": [
					{"text": "Up here the wind carried the sirens away."},
					{"text": "He lit one last cigarette and waited.", "fx": ["lighter"]},
					{"text": "Thunder rolled across the basin.", "fx": ["lightning"]},
				],
			},
		],
	}
