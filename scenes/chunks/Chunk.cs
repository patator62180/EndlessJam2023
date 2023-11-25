using Godot;
using System;

public partial class Chunk : StaticBody2D
{
    [Export]
    CollisionShape2D collisionShape;

    public CollisionShape2D CollisionShape => collisionShape;

    public SegmentShape2D Segment => collisionShape.Shape as SegmentShape2D;

    public void DisableSegment()
    {
        CollisionShape.Hide();
        CollisionShape.Disabled = true;
    }
}
