using Godot;
using System;

public partial class Frog : Node2D
{
	const float Velocity = 200f;

	[Export]
	Node2D leftArm;

	[Export]
	Node2D rightArm;

	private Vector2 screenSize;
	private Viewport viewport;

	private Vector2 leftArmRange = new Vector2(/*up*/Mathf.DegToRad(-113f), /*down*/Mathf.DegToRad(-31.8f));
	private Vector2 rightArmRange = new Vector2(/*up*/Mathf.DegToRad(-127f), /*down*/Mathf.DegToRad(-26.5f));

	public override void _Ready()
	{
		viewport = GetViewport();
		screenSize = viewport.GetVisibleRect().Size;
	}

	public override void _Process(double delta)
	{
		var mouseTarget = Mathf.Max(0, Mathf.Min(viewport.GetMousePosition().Y / screenSize.Y, 1));

		leftArm.Rotation = leftArmRange.X + (leftArmRange.Y - leftArmRange.X) * mouseTarget;
		rightArm.Rotation = rightArmRange.X + (rightArmRange.Y - rightArmRange.X) * mouseTarget;

		if (Input.IsActionPressed("move_right"))
		{
			Position = Position.Lerp(Position + new Vector2(Velocity * (float)delta, -Velocity * (float)delta), .5f);
		}
	}
}
