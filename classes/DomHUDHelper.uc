class DomHUDHelper extends Mutator;

var DomHUDOverlay ParentMutator;
var bool bHUDMutatorSet;
var PlayerPawn OwnerPlayer;

var Mutator LocalNextHUDMutator;

replication
{
    reliable if (Role == ROLE_Authority)
        ParentMutator, OwnerPlayer;
}

simulated function Tick(float DeltaTime)
{
    if (Level.NetMode != NM_DedicatedServer && !bHUDMutatorSet)
    {
        if (OwnerPlayer != None && OwnerPlayer.myHUD != None)
        {
            LocalNextHUDMutator = OwnerPlayer.myHUD.HUDMutator;
            OwnerPlayer.myHUD.HUDMutator = Self;
            bHUDMutatorSet = true;
        }
    }
}

event Destroyed()
{
    if (OwnerPlayer != None && OwnerPlayer.myHUD != None)
    {
        if (OwnerPlayer.myHUD.HUDMutator == Self)
            OwnerPlayer.myHUD.HUDMutator = LocalNextHUDMutator;
    }

    LocalNextHUDMutator = None;
    Super.Destroyed();
}

simulated function PostRender(Canvas Canvas)
{
    if (Canvas == None)
        return;

    if (ParentMutator != None)
        ParentMutator.PostRender(Canvas);

    if (LocalNextHUDMutator != None)
        LocalNextHUDMutator.PostRender(Canvas);
}

defaultproperties
{
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
