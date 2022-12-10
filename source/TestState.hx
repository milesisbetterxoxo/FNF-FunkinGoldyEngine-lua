package;

class TestState extends MusicBeatState
{
    var stage:Stage;

    public function new() {
       super();
    }

    override function create()
    {
        stage = new Stage();
        stage.newSprite('placeholder', false, null);
        for (sprite in stage.sprites)
        {
            sprite.screenCenter();
        }
        add(stage);

        super.create();
    }
}