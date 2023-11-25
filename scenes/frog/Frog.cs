using Godot;
using System;
using System.Linq;

public partial class Frog : CharacterBody2D
{
    const float VelocityScale = 200f;
    const string BallGroup = "ball";
    const string MoveRightInput = "move_right";

    [Export]
    Node2D leftArm;

    [Export]
    Node2D rightArm;

    [Export]
    Area2D hand;

    [Export]
    Area2D wrist;

    private Vector2 screenSize;
    private Viewport viewport;

    private Vector2 leftArmRange = new Vector2(/*up*/Mathf.DegToRad(-113f), /*down*/Mathf.DegToRad(-31.8f));
    private Vector2 rightArmRange = new Vector2(/*up*/Mathf.DegToRad(-127f), /*down*/Mathf.DegToRad(-26.5f));
    private RigidBody2D ball;
    private bool handTouchingBall;
    private bool wristTouchingBall;

    public override void _Ready()
    {
        viewport = GetViewport();
        screenSize = viewport.GetVisibleRect().Size;
        hand.BodyEntered += HandHadBodyEntered;
        hand.BodyExited += HandHadBodyExited;
        wrist.BodyEntered += WristHadBodyEntered;
        wrist.BodyExited += WristHadBodyExited;

        var ballGroup = GetTree().GetNodesInGroup(BallGroup);

        if (ballGroup.Count > 0)
        {
            ball = ballGroup.First() as RigidBody2D;
        }
    }

    private void WristHadBodyExited(Node2D body)
    {
        if (body.IsInGroup(BallGroup))
        {
            wristTouchingBall = false;
        }
    }

    private void WristHadBodyEntered(Node2D body)
    {
        if (body.IsInGroup(BallGroup))
        {
            wristTouchingBall = true;
        }
    }

    private void HandHadBodyExited(Node2D body)
    {
        if (body.IsInGroup(BallGroup))
        {
            handTouchingBall = false;
        }
    }

    private void HandHadBodyEntered(Node2D body)
    {
        if (body.IsInGroup(BallGroup))
        {
            handTouchingBall = true;
        }
    }

    public override void _Process(double delta)
    {
        var mouseTarget = Mathf.Max(0, Mathf.Min(viewport.GetMousePosition().Y / screenSize.Y, 1));
        var movingRight = Input.IsActionPressed(MoveRightInput);

        leftArm.Rotation = leftArmRange.X + (leftArmRange.Y - leftArmRange.X) * mouseTarget;
        rightArm.Rotation = rightArmRange.X + (rightArmRange.Y - rightArmRange.X) * mouseTarget;

        var velocity = Velocity;

        velocity.Y += (float)delta * 200f;

        if (movingRight && !wristTouchingBall)
        {
            velocity.X = VelocityScale;
        }

        Velocity = velocity;

        MoveAndSlide();

        if (!movingRight && handTouchingBall)
        {
            ball.Sleeping = true;
        }
        else if (movingRight && handTouchingBall)
        {
            ball.Sleeping = false;
            ball.LinearVelocity = new Vector2(VelocityScale * 2, 0);
        }
        else if (!handTouchingBall)
        {
            ball.Sleeping = false;
        }
    }
}
