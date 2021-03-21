type
  MeleeCharacter* {.pure.} = enum
    Mario = 0x00,
    Fox = 0x01,
    CaptainFalcon = 0x02,
    DonkeyKong = 0x03,
    Kirby = 0x04,
    Bowser = 0x05,
    Link = 0x06,
    Sheik = 0x07,
    Ness = 0x08,
    Peach = 0x09,
    Popo = 0x0a,
    Nana = 0x0b,
    Pikachu = 0x0c,
    Samus = 0x0d,
    Yoshi = 0x0e,
    Jigglypuff = 0x0f,
    Mewtwo = 0x10,
    Luigi = 0x11,
    Marth = 0x12,
    Zelda = 0x13,
    YoungLink = 0x14,
    DoctorMario = 0x15,
    Falco = 0x16,
    Pichu = 0x17,
    MrGameAndWatch = 0x18,
    Ganondorf = 0x19,
    Roy = 0x1a,
    WireFrameMale = 0x1d,
    WireFrameFemale = 0x1e,
    GigaBowser = 0x1f,
    SandBag = 0x20,
    UnknownCharacter = 0xff,

  MeleeActionState* {.pure.} = enum
    DeadDown = 0x0,
    DeadLeft = 0x1,
    DeadRight = 0x2,
    DeadUp = 0x3,
    DeadUpStar = 0x4,
    DeadUpStarIce = 0x5,
    Unused1 = 0x6,
    Unused2 = 0x7,
    DeadUpFallHitCamera = 0x8,
    DeadUpFallIce = 0x9,
    DeadUpFallHitCameraIce = 0xa,
    Sleep = 0xb,
    HaloDescent = 0xc,
    HaloWait = 0x0d,
    Wait = 0x0e,
    WalkSlow = 0x0f,
    WalkMiddle = 0x10,
    WalkFast = 0x11,
    Turn = 0x12,
    TurnRun = 0x13,
    Dash = 0x14,
    Run = 0x15,
    RunDirect = 0x16,
    RunBrake = 0x17,
    JumpSquat = 0x18,
    JumpForward = 0x19,
    JumpBack = 0x1A,
    JumpAerialForward = 0x1b,
    JumpAerialBack = 0x1c,
    Fall = 0x1D,
    FallForward = 0x1e,
    FallBack = 0x1f,
    FallAerial = 0x20,
    FallAerialForward = 0x21,
    FallAerialBack = 0x22,
    FallSpecial = 0x23,
    FallSpecialForward = 0x24,
    FallSpecialBack = 0x25,
    Tumbling = 0x26,
    Crouch = 0x27,
    CrouchWait = 0x28,
    CrouchToStand = 0x29,
    Landing = 0x2a,
    LandingFallSpecial = 0x2b,
    Jab1 = 0x2c,
    Jab2 = 0x2d,
    Jab3 = 0x2e,
    RapidJabStart = 0x2f,
    RapidJabMiddle = 0x30,
    RapidJabEnd = 0x31,
    DashAttack = 0x32,
    ForwardTiltHigh = 0x33,
    ForwardTiltHighMid = 0x34,
    ForwardTiltMid = 0x35,
    ForwardTiltLowMid = 0x36,
    ForwardTiltLow = 0x37,
    UpTilt = 0x38,
    DownTilt = 0x39,
    ForwardSmashHigh = 0x3a,
    ForwardSmashMidHigh = 0x3b,
    ForwardSmashMid = 0x3c,
    ForwardSmashMidLow = 0x3d,
    ForwardSmashLow = 0x3e,
    UpSmash = 0x3f,
    DownSmash = 0x40,
    NeutralAir = 0x41,
    ForwardAir = 0x42,
    BackAir = 0x43,
    UpAir = 0x44,
    DownAir = 0x45,
    NeutralAirLanding = 0x46,
    ForwardAirLanding = 0x47,
    BackAirLanding = 0x48,
    UpAirLanding = 0x49,
    DownAirLanding = 0x4a,
    DamageHigh1 = 0x4b,
    DamageHigh2 = 0x4c,
    DamageHigh3 = 0x4d,
    DamageNeutral1 = 0x4e,
    DamageNeutral2 = 0x4f,
    DamageNeutral3 = 0x50,
    DamageLow1 = 0x51,
    DamageLow2 = 0x52,
    DamageLow3 = 0x53,
    DamageAir1 = 0x54,
    DamageAir2 = 0x55,
    DamageAir3 = 0x56,
    DamageFlyHigh = 0x57,
    DamageFlyNeutral = 0x58,
    DamageFlyLow = 0x59,
    DamageFlyTop = 0x5a,
    DamageFlyRoll = 0x5b,
    ItemPickupLight = 0x5c,
    ItemPickupHeavy = 0x5d,
    ItemThrowLightForward = 0x5e,
    ItemThrowLightBack = 0x5f,
    ItemThrowLightHigh = 0x60,
    ItemThrowLightLow = 0x61,
    ItemThrowLightDash = 0x62,
    ItemThrowLightDrop = 0x63,
    ItemThrowLightAirForward = 0x64,
    ItemThrowLightAirBack = 0x65,
    ItemThrowLightAirHigh = 0x66,
    ItemThrowLightAirLow = 0x67,
    ItemThrowHeavyForward = 0x68,
    ItemThrowHeavyBack = 0x69,
    ItemThrowHeavyHigh = 0x6a,
    ItemThrowHeavyLow = 0x6b,
    ItemThrowLightSmashForward = 0x6c,
    ItemThrowLightSmashBack = 0x6D,
    ItemThrowLightSmashUp = 0x6e,
    ItemThrowLightSmashDown = 0x6f,
    ItemThrowLightAirSmashForward = 0x70,
    ItemThrowLightAirSmashBack = 0x71,
    ItemThrowLightAirSmashHigh = 0x72,
    ItemThrowLightAirSmashLow = 0x73,
    ItemThrowHeavyAirSmashForward = 0x74,
    ItemThrowHeavyAirSmashBack = 0x75,
    ItemThrowHeavyAirSmashHigh = 0x76,
    ItemThrowHeavyAirSmashLow = 0x77,
    BeamSwordSwing1 = 0x78,
    BeamSwordSwing2 = 0x79,
    BeamSwordSwing3 = 0x7a,
    BeamSwordSwing4 = 0x7b,
    BatSwing1 = 0x7c,
    BatSwing2 = 0x7d,
    BatSwing3 = 0x7e,
    BatSwing4 = 0x7f,
    ParasolSwing1 = 0x80,
    ParasolSwing2 = 0x81,
    ParasolSwing3 = 0x82,
    ParasolSwing4 = 0x83,
    FanSwing1 = 0x84,
    FanSwing2 = 0x85,
    FanSwing3 = 0x86,
    FanSwing4 = 0x87,
    StarRodSwing1 = 0x88,
    StarRodSwing2 = 0x89,
    StarRodSwing3 = 0x8a,
    StarRodSwing4 = 0x8b,
    LipStickSwing1 = 0x8c,
    LipStickSwing2 = 0x8d,
    LipStickSwing3 = 0x8e,
    LipStickSwing4 = 0x8f,
    ItemParasolOpen = 0x90,
    ItemParasolFall = 0x91,
    ItemParasolFallSpecial = 0x92,
    ItemParasolDamageFall = 0x93,
    GunShoot = 0x94,
    GunShootAir = 0x95,
    GunShootEmpty = 0x96,
    GunShootAirEmpty = 0x97,
    FireFlowerShoot = 0x98,
    FireFlowerShootAir = 0x99,
    ItemScrew = 0x9a,
    ItemScrewAir = 0x9b,
    DamageScrew = 0x9c,
    DamageScrewAir = 0x9d,
    ItemScopeStart = 0x9e,
    ItemScopeRapid = 0x9f,
    ItemScopeFire = 0xa0,
    ItemScopeEnd = 0xa1,
    ItemScopeAirStart = 0xa2,
    ItemScopeAirRapid = 0xa3,
    ItemScopeAirFire = 0xa4,
    ItemScopeAirEnd = 0xa5,
    ItemScopeStartEmpty = 0xa6,
    ItemScopeRapidEmpty = 0xa7,
    ItemScopeFireEmpty = 0xa8,
    ItemScopeEndEmpty = 0xa9,
    ItemScopeAirStartEmpty = 0xaa,
    ItemScopeAirRapidEmpty = 0xab,
    ItemScopeAirFireEmpty = 0xac,
    ItemScopeAirEndEmpty = 0xad,
    LiftWait = 0xae,
    LiftWalk1 = 0xaf
    LiftWalk2 = 0xb0,
    LiftTurn = 0xb1,
    ShieldStart = 0xb2,
    Shield = 0xb3,
    ShieldRelease = 0xb4,
    ShieldStun = 0xb5,
    ShieldReflect = 0xb6,
    TechMissUp = 0xb7,
    LyingGroundUp = 0xb8,
    LyingGroundUpHit = 0xb9,
    GroundGetup = 0xba,
    GroundAttackUp = 0xbb,
    GroundRollForwardUp = 0xbc,
    GroundRollBackwardUp = 0xbd,
    GroundSpotUp = 0xbe,
    TechMissDown = 0xbf,
    LyingGroundDown = 0xc0,
    DamageGround = 0xc1,
    NeutralGetup = 0xc2,
    GetupAttack = 0xc3,
    GroundRollForwardDown = 0xc4,
    GroundRollBackwardDown = 0xc5,
    GroundRollSpotDown = 0xc6,
    NeutralTech = 0xc7,
    ForwardTech = 0xc8,
    BackTech = 0xc9,
    WallTech = 0xca,
    WallTechJump = 0xcb,
    CeilingTech = 0xcc,
    ShieldBreakFly = 0xcd,
    ShieldBreakFall = 0xce,
    ShieldBreakDownU = 0xcf,
    ShieldBreakDownD = 0xd0,
    ShieldBreakStandU = 0xd1,
    ShieldBreakStandD = 0xd2,
    ShieldBreakTeeter = 0xd3,
    Grab = 0xd4,
    GrabPulling = 0xd5,
    GrabRunning = 0xd6,
    GrabRunningPulling = 0xd7,
    GrabWait = 0xd8,
    GrabPummel = 0xd9,
    GrabBreak = 0xda,
    ThrowForward = 0xdb,
    ThrowBack = 0xdc,
    ThrowUp = 0xdd,
    ThrowDown = 0xde,
    GrabPullingHigh = 0xdf,
    GrabbedWaitHigh = 0xe0,
    GrabPummeledHigh = 0xe1,
    GrabPull = 0xe2,
    Grabbed = 0xe3,
    GrabPummeled = 0xe4,
    GrabEscape = 0xe5,
    GrabJump = 0xe6,
    GrabNeck = 0xe7,
    GrabFoot = 0xe8,
    RollForward = 0xe9,
    RollBack = 0xea,
    SpotDodge = 0xeb,
    AirDodge = 0xec,
    ReboundStop = 0xed,
    Rebound = 0xee,
    ThrownForward = 0xef,
    ThrownBack = 0xf0,
    ThrownUp = 0xf1,
    ThrownDown = 0xf2,
    ThrownDown2 = 0xf3,
    PlatformDrop = 0xf4,
    EdgeTeeteringStart = 0xf5,
    EdgeTeetering = 0xf6,
    BounceWall = 0xf7,
    BounceCeiling = 0xf8,
    BumpWall = 0xf9,
    BumpCieling = 0xfa,
    SlidingOffEdge = 0xfb,
    EdgeCatching = 0xfc,
    EdgeHanging = 0xfd,
    EdgeGetupSlow = 0xfe,
    EdgeGetupQuick = 0xff,
    EdgeAttackSlow = 0x100,
    EdgeAttackQuick = 0x101,
    EdgeRollSlow = 0x102,
    EdgeRollQuick = 0x103,
    EdgeJump1Slow = 0x104,
    EdgeJump2Slow = 0x105,
    EdgeJump1Quick = 0x106,
    EdgeJump2Quick = 0x107,
    TauntRight = 0x108,
    TauntLeft = 0x109,
    ShoulderedWait = 0x10A,
    ShoulderedWalkSlow = 0x10b,
    ShoulderedWalkMiddle = 0x10c,
    ShoulderedWalkFast = 0x10d,
    ShoulderedTurn = 0x10e,
    ThrownFForward = 0x10f,
    ThrownFBack = 0x110,
    ThrownFHigh = 0x111,
    ThrownFLow = 0x112,
    CaptureCaptain = 0x113,
    CaptureYoshi = 0x114,
    YoshiEgg = 0x115,
    CaptureKoopa = 0x116
    CaptureDamageKoopa = 0x117,
    CaptureWaitKoopa = 0x118,
    ThrownKoopaForward = 0x119,
    ThrownKoopaBack = 0x11A,
    CaptureKoopaAir = 0x11B,
    CaptureDamageKoopaAir = 0x11c,
    CaptureWaitKoopaAir = 0x11d,
    ThrownKoopaAirForward = 0x11e,
    ThrownKoopaAirBack = 0x11f,
    CaptureKirby = 0x120,
    CaptureWaitKirby = 0x121,
    ThrownKirbyStar = 0x122,
    ThrownCopyStar = 0x123,
    ThrownKirby = 0x124,
    BarrelWait = 0x125,
    Bury = 0x126,
    BuryWait = 0x127,
    BuryJump = 0x128,
    DamageSong = 0x129,
    DamageSongWait = 0x12A,
    DamageSongRv = 0x12B,
    DamageBind = 0x12C,
    CaptureMewtwo = 0x12D,
    CaptureMewtwoAir = 0x12E,
    ThrownMewtwo = 0x12F,
    ThrownMewtwoAir = 0x130,
    WarpStarJump = 0x131,
    WarpStapFall = 0x132,
    HammerWait = 0x133,
    HammerWalk = 0x134,
    HammerTurn = 0x135,
    HammerKneeBend = 0x136,
    HammerFall = 0x137,
    HammerJump = 0x138,
    HammerLanding = 0x139,
    KinokoGiantStart = 0x13a,
    KinokoGiantStartAir = 0x13B,
    KinokoGiantEnd = 0x13c,
    KinokoGiantEndAir = 0x13d,
    KinokoSmallStart = 0x13e,
    KinokoSmallStartAir = 0x13f,
    KinokoSmallEnd = 0x140,
    KinokoSmallEndAir = 0x141,
    Entry = 0x142,
    EntryStart = 0x143,
    EntryEnd = 0x144,
    DamageIce = 0x145,
    DamageIceJump = 0x146,
    CaptureMasterhand = 0x147,
    CaptureDamageMasterhand = 0x148,
    CaptureWaitMasterhand = 0x149,
    ThrownMasterhand = 0x14A,
    CaptureKirbyYoshi = 0x14B,
    KirbyYoshiEgg = 0x14C,
    CaptureLeaDead = 0x14D,
    CaptureLikeLike = 0x14E,
    DownReflect = 0x14F,
    CaptureCrazyhand = 0x150,
    CaptureDamageCrazyhand = 0x151,
    CaptureWaitCrazyhand = 0x152,
    ThrownCrazyHand = 0x153,
    BarrelCannonWait = 0x154,
    Wait1 = 0x155,
    Wait2 = 0x156,
    Wait3 = 0x157,
    Wait4 = 0x158,
    WaitItem = 0x159,
    SquatWait1 = 0x15a,
    SquatWait2 = 0x15b,
    SquatWaitItem = 0x15c,
    GuardDamage = 0x15d,
    EscapeN = 0x15e,
    AttackS4Hold = 0x15f,
    HeavyWalk1 = 0x160,
    HeavyWalk2 = 0x161,
    ItemHammerWait = 0x162,
    ItemHammerMove = 0x163,
    ItemBlind = 0x164,
    DamageElectric = 0x165,
    FuraSleepStart = 0x166,
    FuraSleepLoop = 0x167,
    FuraSleepEnd = 0x168,
    WallDamage = 0x169,
    CliffWait1 = 0x16a,
    CliffWait2 = 0x16b,
    SlipDown = 0x16c,
    Slip = 0x16d,
    SlipTurn = 0x16e,
    SlipDash = 0x16f,
    SlipWait = 0x170,
    SlipStand = 0x171,
    SlipAttack = 0x172,
    SlipEscapeForward = 0x173,
    SlipEscapeBack = 0x174,
    AppealS = 0x175,
    Zitabata = 0x176,
    CaptureKoopaHit = 0x177,
    ThrownKoopaEndForward = 0x178,
    ThrownKoopaEndBack = 0x179,
    CaptureKoopaAirHit = 0x17a,
    ThrownKoopaAirEndForward = 0x17b,
    ThrownKoopaAirEndBack = 0x17c,
    ThrownKirbyDrinkSShot = 0x17d,
    ThrownKirbySpitSShot = 0x17e,
    Unknown = 0xffff,

  MeleeAttack* {.pure.} = enum
    NotAttack = 0x0,
    NonStaling = 0x1,
    Jab1 = 0x2,
    Jab2 = 0x3,
    Jab3 = 0x4,
    RapidJabs = 0x5,
    DashAttack = 0x6,
    SideTilt = 0x7,
    UpTilt = 0x8,
    DownTilt = 0x9,
    SideSmash = 0xa,
    UpSmash = 0xb,
    DownSmash = 0xc,
    NeutralAir = 0xd,
    ForwardAir = 0xe,
    BackAir = 0xf,
    UpAir = 0x10,
    DownAir = 0x11,
    NeutralSpecial = 0x12,
    SideSpecial = 0x13,
    UpSpecial = 0x14,
    DownSpecial = 0x15,
    KirbyMarioSpecial = 0x16,
    KirbyFoxSpecial = 0x17,
    KirbyCaptainFalconSpecial = 0x18,
    KirbyDonkeyKongSpecial = 0x19,
    KirbyBowserSpecial = 0x1a,
    KirbyLinkSpecial = 0x1b,
    KirbySheikSpecial = 0x1c,
    KirbyNessSpecial = 0x1d,
    KirbyPeachSpecial = 0x1e,
    KirbyIceClimbersSpecial = 0x1f,
    KirbyPikachuSpecial = 0x20,
    KirbySamusSpecial = 0x21,
    KirbyYoshiSpecial = 0x22,
    KirbyJigglypuffSpecial = 0x23,
    KirbyMewtwoSpecial = 0x24,
    KirbyLuigiSpecial = 0x25,
    KirbyMarthSpecial = 0x26,
    KirbyZeldaSpecial = 0x27,
    KirbyYoungLinkSpecial = 0x28,
    KirbyDoctorMarioSpecial = 0x29,
    KirbyFalcoSpecial = 0x2a,
    KirbyPichuSpecial = 0x2b,
    KirbyMrGameAndWatchSpecial = 0x2c,
    KirbyGanondorfSpecial = 0x2d,
    KirbyRoySpecial = 0x2e,
    Unknown1 = 0x2f,
    Unknown2 = 0x30,
    Unknown3 = 0x31,
    GetUpAttackBack = 0x32,
    GetUpAttackFront = 0x33,
    Pummel = 0x34,
    ForwardThrow = 0x35,
    BackThrow = 0x36,
    UpThrow = 0x37,
    DownThrow = 0x38,
    CargoForwardThrow = 0x39,
    CargoBackThrow = 0x3a,
    CargoUpThrow = 0x3b,
    CargoDownThrow = 0x3c,
    LedgeGetUpAttackSlow = 0x3d,
    LedgeGetUpAttack = 0x3e,
    BeamSwordJab = 0x3f,
    BeamSwordTilt = 0x40,
    BeamSwordSmash = 0x41,
    BeamSwordDash = 0x42,
    HomeRunBatJab = 0x43,
    HomeRunBatTilt = 0x44,
    HomeRunBatSmash = 0x45,
    HomeRunBatDash = 0x46,
    ParasolJab = 0x47,
    ParasolTilt = 0x48,
    ParasolSmash = 0x49,
    ParasolDash = 0x4a,
    FanJab = 0x4b,
    FanTilt = 0x4c,
    FanSmash = 0x4d,
    FanDash = 0x4e,
    StarRodJab = 0x4f,
    StarRodTilt = 0x50,
    StarRodSmash = 0x51,
    StarRodDash = 0x52,
    LipStickJab = 0x53,
    LipStickTilt = 0x54,
    LipStickSmash = 0x55,
    LipStickDash = 0x56,
    ParasolOpen = 0x57,
    RayGunShoot = 0x58,
    FireFlowerShoot = 0x59,
    ScrewAttack = 0x5a,
    SuperScopeRapid = 0x5b,
    SuperScopeCharged = 0x5c,
    Hammer = 0x5d,

  MeleeLCancelStatus* {.pure.} = enum
    None = 0,
    Successful = 1,
    Unsuccessful = 2,

  MeleeHurtboxCollisionState* {.pure.} = enum
    Vulnerable = 0,
    Invulnerable = 1,
    Intangible = 2,

  MeleePlayerState* = object
    playerIndex*: int
    isFollower*: bool
    character*: MeleeCharacter
    actionState*: MeleeActionState
    xPosition*: float
    yPosition*: float
    isFacingRight*: bool
    percent*: float
    shieldSize*: float
    lastHittingAttack*: MeleeAttack
    currentComboCount*: int
    reflectIsActive*: bool
    isInvincible*: bool
    isFastFalling*: bool
    isInHitlag*: bool
    isShielding*: bool
    isInHitstun*: bool
    detectionHitboxIsTouchingShield*: bool
    isPowershielding*: bool
    isSleeping*: bool
    isDead*: bool
    isOffscreen*: bool
    lastHitBy*: int
    stocksRemaining*: int
    actionStateFrameCounter*: float
    hitstunRemaining*: float
    isAirborne*: bool
    lastGroundId*: int
    jumpsRemaining*: int
    lCancelStatus*: MeleeLCancelStatus
    hurtboxCollisionState*: MeleeHurtboxCollisionState
    selfInducedAirXSpeed*: float
    selfInducedYSpeed*: float
    attackBasedXSpeed*: float
    attackBasedYSpeed*: float
    selfInducedGroundXSpeed*: float
    hitlagFramesRemaining*: float

  MeleeGameState* = object
    frameNumber*: int
    playerStates*: array[4, MeleePlayerState]
    followerStates*: array[4, MeleePlayerState]