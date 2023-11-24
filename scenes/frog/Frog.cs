using Godot;
using System;

public partial class Frog : Node2D
{
    const float Velocity = 200f;

    public override void _Ready()
    {
    }

    public override void _Process(double delta)
    {
        if (Input.IsActionPressed("move_right"))
        {
            Position = Position.Lerp(Position + new Vector2(Velocity * (float)delta, -Velocity * (float)delta), .5f);
        }
    }
}
