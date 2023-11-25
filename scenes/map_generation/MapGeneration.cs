using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class MapGeneration : Node2D
{
    const int ChunkTypeSquare = 0;


    [Export]
    Chunk startChunk;

    [Export]
    PackedScene[] packedChunks;

    [Export]
    Node2D chunksRoot;

    [Export]
    CollisionPolygon2D collisionPolygon;

    int polygonMinimumHeight = 200;
    int yPrecision = 10;

    List<Vector2> points = new List<Vector2>();
    List<Chunk> chunks = new List<Chunk>();

    public override void _Ready()
    {
        Random random = new Random();
        var previousChunk = startChunk;
        var chunkTypes = new List<int>();

        chunks.Add(startChunk);
        points.Add(startChunk.Position + startChunk.Segment.A);

        for (var index = 0; index < 50; ++index)
        {
            int chunkType;

            if (chunkTypes.Count() < 2 || (chunkTypes[chunkTypes.Count() - 2] != chunkTypes[chunkTypes.Count() - 1]) && chunkTypes[chunkTypes.Count() - 1] == ChunkTypeSquare)
            {
                chunkType = ChunkTypeSquare;
            }
            else
            {
                chunkType = random.Next(0, 2);
            }

            var newChunk = AttachNewChunk(previousChunk, packedChunks[chunkType]);
            var newPoint = newChunk.Position + newChunk.Segment.A;

            RemoveExtraPoints(newPoint);
            points.Add(newPoint);
            chunks.Add(newChunk);
            chunkTypes.Add(chunkType);

            previousChunk = newChunk;
        }

        var lastChunkRightPoint = chunks.Last().Position + chunks.Last().Segment.B;

        RemoveExtraPoints(lastChunkRightPoint);
        points.Add(lastChunkRightPoint);


        points.Add(new Vector2(points.Last().X, points.First().Y + polygonMinimumHeight));
        points.Add(new Vector2(points.First().X, points.First().Y + polygonMinimumHeight));
        points.Add(points.First());

        collisionPolygon.Polygon = points.ToArray();


        foreach (var chunk in chunks)
        {
            chunk.DisableSegment();
        }
    }

    void RemoveExtraPoints(Vector2 newPoint)
    {
        if (points.Count() >= 2)
        {
            var pA = points[points.Count() - 2];
            var pB = points[points.Count() - 1];
            var pC = newPoint;

            var alignedY = pA.Y + (pC.Y - pA.Y) * (pB.X - pA.X) / (pC.X - pA.X);

            if (Mathf.Abs(alignedY - pB.Y) <= yPrecision)
            {
                points.Remove(pB);
            }
        }
    }

    Chunk AttachNewChunk(Chunk previousChunk, PackedScene packedChunk)
    {
        var newChunk = packedChunk.Instantiate() as Chunk;
        chunksRoot.AddChild(newChunk);

        newChunk.Position = new Vector2(previousChunk.Segment.B.X + previousChunk.Position.X - newChunk.Segment.A.X, previousChunk.Position.Y + previousChunk.Segment.B.Y - newChunk.Segment.A.Y);

        return newChunk;
    }

    public override void _Process(double delta)
    {
    }
}
