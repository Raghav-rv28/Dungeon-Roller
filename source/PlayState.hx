package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;

/**
 * @author Raghav
 */
class PlayState extends FlxState
{
	static var _justDied:Bool = false;

	public var walls:FlxTilemap;
	public var map:FlxOgmo3Loader;
	public var player:FlxSprite;
	public var exit:FlxSprite;
	public var coinCount:FlxText;

	// Objects
	var coins:FlxTypedGroup<Coin>;
	var bombs:FlxTypedGroup<Bomb>;

	public var key:FlxObject;
	public var status:FlxText;
	// sounds
	public var bombSound:FlxSound;
	public var coinSound:FlxSound;
	public var winSound:FlxSound;
	public var loseSound:FlxSound;

	override public function create():Void
	{
		// Creates the boundary of the map

		map = new FlxOgmo3Loader(AssetPaths.newmap__ogmo, AssetPaths.room2__json);
		walls = map.loadTilemap(AssetPaths.tiles__png, "walls");
		walls.follow();
		walls.setTileProperties(1, FlxObject.NONE);
		walls.setTileProperties(2, FlxObject.ANY);
		add(walls);

		// Create the complete portal exit

		exit = new FlxSprite(520, 275);
		exit.loadGraphic(AssetPaths.portal__png);
		exit.exists = false;
		add(exit);

		// Coins
		coins = new FlxTypedGroup<Coin>();
		add(coins);

		// Bombs
		bombs = new FlxTypedGroup<Bomb>();
		add(bombs);
		map.loadEntities(placeEntities, "entities");
		// key

		var key:FlxSprite = new FlxSprite(145, 225);
		key.loadGraphic(AssetPaths.key__png);

		// Create player
		player = new FlxSprite(FlxG.width / 2 - 5);
		player.loadGraphic(AssetPaths.character__png);
		player.maxVelocity.set(360, 200);
		player.acceleration.y = 300;
		player.drag.x = player.maxVelocity.x * 4;
		player.x = 80;
		player.y = 16;
		add(player);

		// Counting the Coins and keeping track of Score

		coinCount = new FlxText(2, 2, 80, "SCORE: " + (coins.countDead() * 100));
		coinCount.setFormat(null, 8, FlxColor.WHITE, null, NONE, FlxColor.BLACK);
		add(coinCount);
		// Shows the current status of the game!

		status = new FlxText(FlxG.width - 160 - 2, 2, 160, "Collect coins.");
		status.setFormat(null, 32, FlxColor.WHITE, CENTER, NONE, FlxColor.BLACK);

		if (_justDied)
		{
			status.text = "YOU ARE DEAD!";
			status.size = 32;
			status.alignment = "justify";
			add(status);
			FlxG.resetState();
		}

		add(key);
	}

	override public function update(elapsed:Float):Void
	{
		player.acceleration.x = 0;
		if (FlxG.keys.anyPressed([LEFT]))
		{
			player.acceleration.x = -player.maxVelocity.x * 24;
		}

		if (FlxG.keys.anyPressed([RIGHT]))
		{
			player.acceleration.x = player.maxVelocity.x * 24;
		}
		if (FlxG.keys.anyPressed([SPACE, UP]) && player.isTouching(FlxObject.FLOOR))
		{
			player.velocity.y = -player.maxVelocity.y / 1.35;
		}

		super.update(elapsed);

		// Contacts and how they play out using different Functions

		FlxG.overlap(coins, player, getCoin);
		FlxG.collide(walls, player);
		FlxG.overlap(exit, player, win);
		FlxG.overlap(bombs, player, touchBomb);
		FlxG.overlap(key, player, lastRound);

		// Player Dies if he Falls in the pit.

		if (player.y > FlxG.height)
		{
			loseSound = FlxG.sound.load(AssetPaths.lose__wav);
			loseSound.play();
			_justDied = true;
			FlxG.resetState();
		}
	}

	/**
	 * Function to create entities designed in OGMO loader
	 */
	function placeEntities(entity:EntityData)
	{
		var x = entity.x;
		var y = entity.y;

		switch (entity.name)
		{
			case "coin":
				coins.add(new Coin(x + 4, y + 4));
			case "bomb":
				bombs.add(new Bomb(x + 4, y + 4));
		}
	}

	/**
	 * Function that determinse the condition for winning the game
	 * @param Exit
	 * @param Player
	 */
	function win(Exit:FlxObject, Player:FlxObject):Void
	{
		winSound = FlxG.sound.load(AssetPaths.win__wav);
		winSound.play();
		status.text = "Congratulations!";
		status.size = 32;
		status.alignment = "justify";
		coinCount.text = " SCORE: " + (coins.countDead() * 100);
		player.kill();
	}

	/**
	 * Function to collect Coins and keep track of the Score
	 * @param Coin
	 * @param Player
	 */
	function getCoin(Coin:FlxObject, Player:FlxObject):Void
	{
		Coin.kill();
		coinSound = FlxG.sound.load(AssetPaths.coin__wav);
		coinSound.play();
		coinCount.text = "SCORE: " + (coins.countDead() * 100);

		if (coins.countLiving() == 0)
		{
			status.text = "Find the exit";
			exit.exists = true;
		}
	}

	/**
	 * When you Touch the Bomb You Die!
	 * @param Bomb
	 * @param Player
	 */
	function touchBomb(Bomb:FlxObject, Player:FlxObject):Void
	{
		bombSound = FlxG.sound.load(AssetPaths.hurt__wav);
		bombSound.play();
		coinCount.text = " SCORE: 0";
		_justDied = true;
		FlxG.resetState();
	}

	/**
	 * when the key is collected and score is more than 1000 you can exit through the portal
	 * @param key
	 * @param Player
	 */
	function lastRound(key:FlxObject, Player:FlxObject):Void
	{
		if ((coins.countDead() * 100) >= 1500)
		{
			status.text = "Find the exit";
			exit.exists = true;
		}
	}
}
