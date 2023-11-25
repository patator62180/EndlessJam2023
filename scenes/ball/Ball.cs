using Godot;
using System;

public partial class Ball : RigidBody2D
{
    [Export]
    Sprite2D shadow;


    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
        shadow.Rotation = -Rotation;
    }
}
