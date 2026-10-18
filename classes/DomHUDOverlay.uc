class DomHUDOverlay extends Mutator config(User);

var bool bHUDMutatorSet;
var config bool bShowDOMHUD;
var Texture WhiteTex;
var FontInfo MyFonts;

var ControlPoint CPList[16];
var int NumPoints;

struct TeamPossession {
    var float RedTime;
    var float BlueTime;
};
var TeamPossession PointStats[16];

replication
{
    reliable if (Role == ROLE_Authority)
        PointStats, CPList, NumPoints, bShowDOMHUD;
}

function ModifyPlayer(Pawn Other)
{
    local DomHUDHelper Helper;
    local bool bFound;

    if (NextMutator != None)
        NextMutator.ModifyPlayer(Other);

    if (PlayerPawn(Other) != None)
    {
        foreach AllActors(class'DomHUDHelper', Helper)
        {
            if (Helper.OwnerPlayer == Other)
            {
                bFound = true;
                break;
            }
        }

        if (!bFound)
        {
            Helper = Spawn(class'DomHUDHelper', Other);
            Helper.ParentMutator = Self;
            Helper.OwnerPlayer = PlayerPawn(Other);
        }
    }
}

function Mutate(string MutateString, PlayerPawn Sender)
{
    if (MutateString ~= "ToggleDOMHUD")
    {
        bShowDOMHUD = !bShowDOMHUD;
        SaveConfig();
        Sender.ClientMessage("DOM HUD Overlay: " $ bShowDOMHUD);
    }

    if (NextMutator != None)
        NextMutator.Mutate(MutateString, Sender);
}

function PostBeginPlay()
{
    local ControlPoint CP;
    local int i;

    Super.PostBeginPlay();

    NumPoints = 0;
    for (i = 0; i < 16; i++)
    {
        CPList[i] = None;
        PointStats[i].RedTime = 0.0;
        PointStats[i].BlueTime = 0.0;
    }

    foreach AllActors(class'ControlPoint', CP)
    {
        if (NumPoints < 16)
        {
            CPList[NumPoints] = CP;
            PointStats[NumPoints].RedTime = 0.0;
            PointStats[NumPoints].BlueTime = 0.0;
            NumPoints++;
        }
    }
}

function ResetPointStats(int Index)
{
    if (Index >= 0 && Index < 16)
    {
        PointStats[Index].RedTime = 0.0;
        PointStats[Index].BlueTime = 0.0;
    }
}

function Tick(float DeltaTime)
{
    local int i;
    local int TeamIndex;

    if (Level.Game != None && !Level.Game.bGameEnded)
    {
        for (i = 0; i < NumPoints; i++)
        {
            if (CPList[i] == None)
            {
                ResetPointStats(i);
                continue;
            }

            if (CPList[i].ControllingTeam == None)
                continue;

            TeamIndex = CPList[i].ControllingTeam.TeamIndex;

            if (TeamIndex == 0)
                PointStats[i].RedTime += DeltaTime;
            else if (TeamIndex == 1)
                PointStats[i].BlueTime += DeltaTime;
        }
    }
}

simulated function PostRender(Canvas Canvas)
{
    local float TotalTime, RedRatio, BarWidth, BarHeight, BarX, CurrentPosY;
    local float ScaleRatio, CurrentHUDScale, ResScale;
    local int i;
    local string RedPct, BluePct;
    local ChallengeHUD CHUD;

    if (Canvas == None || Canvas.Viewport == None || Canvas.Viewport.Actor == None)
        return;

    if (!bShowDOMHUD)
        return;

    CHUD = ChallengeHUD(Canvas.Viewport.Actor.myHUD);
    if (CHUD != None)
        CurrentHUDScale = CHUD.HUDScale;
    else
        CurrentHUDScale = 1.0;

    ResScale = Canvas.ClipX / 1920.0;
    ScaleRatio = (CurrentHUDScale / 0.4) * ResScale;

    Canvas.Style = 1;
    Canvas.bNoSmooth = True;

    if (MyFonts == None)
    {
        if (CHUD != None)
            MyFonts = CHUD.MyFonts;

        if (MyFonts == None)
            return;
    }

    if (WhiteTex == None)
        WhiteTex = Texture'Engine.WhiteTexture';

    BarWidth = 7 * ScaleRatio;
    BarHeight = 33 * ScaleRatio;
    BarX = 45 * ScaleRatio;

    Canvas.Font = MyFonts.GetStaticSmallFont(Canvas.ClipX);

    for (i = 0; i < NumPoints; i++)
    {
        if (i == 0) CurrentPosY = Canvas.ClipY - (397 * ScaleRatio);
        else if (i == 1) CurrentPosY = Canvas.ClipY - (313 * ScaleRatio);
        else if (i == 2) CurrentPosY = Canvas.ClipY - (229 * ScaleRatio);
        else CurrentPosY = Canvas.ClipY - (50 * ScaleRatio) - (i * 84 * ScaleRatio);

        TotalTime = PointStats[i].RedTime + PointStats[i].BlueTime;

        Canvas.SetPos(BarX - ScaleRatio, CurrentPosY - ScaleRatio);
        Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
        Canvas.DrawRect(WhiteTex, BarWidth + (2 * ScaleRatio), BarHeight + (2 * ScaleRatio));

        Canvas.SetPos(BarX, CurrentPosY);
        Canvas.DrawColor.R = 40; Canvas.DrawColor.G = 40; Canvas.DrawColor.B = 40;
        Canvas.DrawRect(WhiteTex, BarWidth, BarHeight);

        if (TotalTime > 0.0)
        {
            RedRatio = PointStats[i].RedTime / TotalTime;
            BluePct = int((1.0 - RedRatio) * 100.0) $ "%";
            RedPct = int(RedRatio * 100.0) $ "%";

            Canvas.SetPos(BarX, CurrentPosY);
            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * (1.0 - RedRatio));

            Canvas.SetPos(BarX, CurrentPosY + (BarHeight * (1.0 - RedRatio)));
            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.DrawRect(WhiteTex, BarWidth, BarHeight * RedRatio);

            Canvas.DrawColor.R = 0; Canvas.DrawColor.G = 255; Canvas.DrawColor.B = 255;
            Canvas.SetPos(BarX + BarWidth + (5 * ScaleRatio), CurrentPosY + (BarHeight * (1.0 - RedRatio)) / 2 - (5 * ScaleRatio));
            Canvas.DrawText(BluePct, false);

            Canvas.DrawColor.R = 255; Canvas.DrawColor.G = 0; Canvas.DrawColor.B = 0;
            Canvas.SetPos(BarX + BarWidth + (5 * ScaleRatio), CurrentPosY + (BarHeight * (1.0 - RedRatio)) + (BarHeight * RedRatio) / 2 - (5 * ScaleRatio));
            Canvas.DrawText(RedPct, false);
        }
    }
}

defaultproperties
{
    bShowDOMHUD=True
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
