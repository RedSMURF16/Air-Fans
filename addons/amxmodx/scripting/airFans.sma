/*
*
*	Air Fans by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /af                         "Opens the Air Fan menu."
*       say_team /af                    "Opens the Air Fan menu."
*       af_reload                       "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT             32
#define FAN_KEY             761202
#define FAN_ARRAY_ITEM      pev_iuser1
#define FAN_SEQ_SPIN        0
#define MIN_FRAMERATE       0.1
#define MAX_FRAMERATE       5.0

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const ERROR_FILE[]              = "AirFans_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_FAN
}

enum
{
    DTYPE_INT,
    DTYPE_INT_RANGE,
    DTYPE_FLOAT,
    DTYPE_FLOAT_RANGE,
    DTYPE_VECTOR,
    DTYPE_VECTOR_FLOAT,
    DTYPE_BOOL,
    DTYPE_FLAGS,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_ACTIVE_DELAY       = (1 << 0),
    FLAG_ACTIVE_DURATION    = (1 << 1),
    FLAG_PLAYERS_ONLY       = (1 << 2),

    FLAG_SHOW               = (1 << 3),
    FLAG_GHOST              = (1 << 4),
    FLAG_GROUND             = (1 << 5),
    FLAG_ACTIVE             = (1 << 6),
    FLAG_SOUND              = (1 << 7),
    FLAG_PLAYING            = (1 << 8)
}

enum
{
    ROTATE_MODE_PITCH,
    ROTATE_MODE_YAW,
    ROTATE_MODE_ROLL
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_SMALL,
    SIZE_MID,
    SIZE_LARGE
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR,
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,

    Float:SETTING_DEFAULT_SPAWN_CHANCE,
    Float:SETTING_DEFAULT_ACTIVE_DELAY[2],
    Float:SETTING_DEFAULT_ACTIVE_DURATION[2],
    Float:SETTING_DEFAULT_ACTIVE_COOLDOWN[2],
    Float:SETTING_DEFAULT_BASE_STRENGTH,
    Float:SETTING_DEFAULT_PUSH_STRENGTH,
    Float:SETTING_DEFAULT_PUSH_FREQ[2],
    Float:SETTING_DEFAULT_LENGTH,
    Array:SETTING_DEFAULT_SOUND,

    SETTING_MODEL_SMALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_MID[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_SMALL[3],
    Float:SETTING_MAXS_SMALL[3],
    Float:SETTING_MINS_MID[3],
    Float:SETTING_MAXS_MID[3],
    Float:SETTING_MINS_LARGE[3],
    Float:SETTING_MAXS_LARGE[3],
    Float:SETTING_TRIGGER_SIZE[3],
    Float:SETTING_FRAMERATE_MULTIPLIER,
    SETTING_MAX_TARGETS,

    bool:SETTING_FAN_LOAD,
    Float:SETTING_FAN_RANGE,
    Float:SETTING_FAN_CHECK,
    Float:SETTING_FAN_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP,

    SETTING_SOUND_MENU_NAV[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_MENU_REMOVE[MAX_RESOURCE_PATH_LENGTH],
    SETTING_SOUND_MENU_ALERT[MAX_RESOURCE_PATH_LENGTH],
    SETTING_COLOR_ACTIVE[3],
    SETTING_COLOR_INACTIVE[3]
}

enum _:FAN
{
    FAN_ID,
    FAN_ITEM,
    FAN_FLAGS,
    FAN_TEAM,
    FAN_SIZE,
    FAN_NAME[MAX_VALUE_LENGTH],

    Float:FAN_ORIGIN_START[3],
    Float:FAN_ORIGIN_END[3],
    Float:FAN_ANGLES[3],
    Float:FAN_MINS[3],
    Float:FAN_MAXS[3],
    Float:FAN_DIRECTION[3],
    Float:FAN_LENGTH,
    Float:FAN_TRIGGER_SIZE,
    Float:FAN_FRAMERATE,

    Array:FAN_SOUND,
    FAN_SOUND_CURRENT[MAX_RESOURCE_PATH_LENGTH],
    Float:FAN_SPAWN_CHANCE,
    Float:FAN_ACTIVE_DELAY[2],
    Float:FAN_ACTIVE_DURATION[2],
    Float:FAN_ACTIVE_COOLDOWN[2],
    Float:FAN_PUSH_STRENGTH,
    Float:FAN_PUSH_FREQ[2],

    Float:FAN_NEXT_ENABLE,
    Float:FAN_NEXT_DISABLE,
    Float:FAN_NEXT_PUSH
}

enum _:PLAYER_DATA
{
    PDATA_FAN_GHOST,
    PDATA_FAN_MENU,
    bool:PDATA_FAN_ACTION,
    PDATA_ROTATE_MODE,
    PDATA_ROTATE_SIZE,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_SHOW = 4,
    ROOT_STATUS,

    ROOT_NOCLIP = 7,
    ROOT_GODMODE
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_MODE,
    ROTATE_SIZE,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "airfans"
new const g_szPushClasses[][] =
{
    "player",
    "weaponbox",
    "grenade"
}

new Array:g_aFan,
    Array:g_aFanConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdUpdateClientData, HamHook:g_iFwdSpawn, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iFan, g_iFanConfig,
    g_iMaxPlayers

new g_szRotateMode[][] = {"FAN_ROTATE_PITCH", "FAN_ROTATE_YAW", "FAN_ROTATE_ROLL"}
new g_szRotateSize[][] = {"FAN_ROTATE_SMALL", "FAN_ROTATE_MID", "FAN_ROTATE_LARGE"}

public plugin_init()
{
    register_plugin("Air Fans", PLUGIN_VERSION, "RedSMURF")

    register_clcmd("say /af",       "cmdMenu", ADMIN_RCON, "-- Opens the Air Fans menu.")
    register_clcmd("say_team /af",  "cmdMenu", ADMIN_RCON, "-- Opens the Air Fans menu.")
    register_concmd("fan_reload",   "cmdReload", ADMIN_RCON, "-- Reloads the configuration file")

    register_dictionary("AirFans.txt")

    g_iFwdUpdateClientData = register_forward(FM_UpdateClientData, "fwdUpdateClientData", 1)
    g_iFwdSpawn = RegisterHam(Ham_Spawn, "info_target", "fwdSpawn", 1)
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    DisableForwards()

    register_logevent("eventRoundStart", 2, "1=Round_Start")
    set_task(g_eSettings[SETTING_FAN_TASK], "fanTask", .flags = "b")

    fanInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aFan = ArrayCreate(FAN)
    g_aFanConfig = ArrayCreate(FAN)
    g_eSettings[SETTING_DEFAULT_SOUND] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    new eFan[FAN]
    for ( new i = 0; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)
        ArrayDestroy(eFan[FAN_SOUND])
    }

    ArrayDestroy(g_aFan)
    ArrayDestroy(g_aFanConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    fanSound(id, SOUND_MENU_NAV)
    fanMenu(id, MENU_ROOT)

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    if ( !g_iFan )
        return PLUGIN_HANDLED

    new eFan[FAN]
    for ( new i = 0; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)
        if ( !(eFan[FAN_FLAGS] & FLAG_SHOW) )
            continue

        fanReset(eFan)
        if ( eFan[FAN_SPAWN_CHANCE] >= random_float(0.0, 1.0) )
        {
            eFan[FAN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)

            fanSetState(eFan)
            fanSetDelay(eFan)
        }

        ArraySetArray(g_aFan, i, eFan)
    }

    return PLUGIN_HANDLED
}

ReadFile()
{
    new eFan[FAN]
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id))
                UpdateData(id)

        for ( new i = 0; i < g_iFan; i ++ )
        {
            ArrayGetArray(g_aFan, i, eFan)
            ArrayDestroy(eFan[FAN_SOUND])
        }

        ArrayClear(g_aFanConfig)
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND])
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/AirFans.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iFanConfig )
                            ArrayPushArray(g_aFanConfig, eFan)

                        copy(eFan[FAN_NAME], charsmax(eFan[FAN_NAME]), szData)
                        eFan[FAN_FLAGS]               = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eFan[FAN_TEAM]                = g_eSettings[SETTING_DEFAULT_TEAM]
                        eFan[FAN_SPAWN_CHANCE]        = g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE]
                        eFan[FAN_ACTIVE_DELAY][0]     = g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY][0]
                        eFan[FAN_ACTIVE_DELAY][1]     = g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY][1]
                        eFan[FAN_ACTIVE_DURATION][0]  = g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION][0]
                        eFan[FAN_ACTIVE_DURATION][1]  = g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION][1]
                        eFan[FAN_ACTIVE_COOLDOWN][0]  = g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN][0]
                        eFan[FAN_ACTIVE_COOLDOWN][1]  = g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN][1]
                        eFan[FAN_PUSH_STRENGTH]       = g_eSettings[SETTING_DEFAULT_PUSH_STRENGTH]
                        eFan[FAN_PUSH_FREQ][0]        = g_eSettings[SETTING_DEFAULT_PUSH_FREQ][0]
                        eFan[FAN_PUSH_FREQ][1]        = g_eSettings[SETTING_DEFAULT_PUSH_FREQ][1]
                        eFan[FAN_LENGTH]              = g_eSettings[SETTING_DEFAULT_LENGTH]
                        eFan[FAN_SOUND]               = ArrayClone(g_eSettings[SETTING_DEFAULT_SOUND])

                        iSection = SECTION_FAN
                        g_iFanConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPAWN_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE], charsmax(g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_DELAY") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_DURATION") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_ACTIVE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BASE_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BASE_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_BASE_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_PUSH_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_PUSH_STRENGTH], charsmax(g_eSettings[SETTING_DEFAULT_PUSH_STRENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_PUSH_FREQ") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_PUSH_FREQ], charsmax(g_eSettings[SETTING_DEFAULT_PUSH_FREQ]))
                        else if ( equali(szKey, "SETTING_DEFAULT_LENGTH") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_LENGTH], charsmax(g_eSettings[SETTING_DEFAULT_LENGTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND") )
                            parseSetting(DTYPE_ARRAY_SOUND, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND], charsmax(g_eSettings[SETTING_DEFAULT_SOUND]))
                        else if ( equali(szKey, "SETTING_MODEL_SMALL") )
                            parseSetting(DTYPE_STRING_MODEL, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_SMALL], charsmax(g_eSettings[SETTING_MODEL_SMALL]))
                        else if ( equali(szKey, "SETTING_MODEL_MID") )
                            parseSetting(DTYPE_STRING_MODEL, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_MID], charsmax(g_eSettings[SETTING_MODEL_MID]))
                        else if ( equali(szKey, "SETTING_MODEL_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_LARGE], charsmax(g_eSettings[SETTING_MODEL_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_SMALL") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MINS_SMALL], charsmax(g_eSettings[SETTING_MINS_SMALL]))
                        else if ( equali(szKey, "SETTING_MAXS_SMALL") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_SMALL], charsmax(g_eSettings[SETTING_MAXS_SMALL]))
                        else if ( equali(szKey, "SETTING_MINS_MID") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MINS_MID], charsmax(g_eSettings[SETTING_MINS_MID]))
                        else if ( equali(szKey, "SETTING_MAXS_MID") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_MID], charsmax(g_eSettings[SETTING_MAXS_MID]))
                        else if ( equali(szKey, "SETTING_MINS_LARGE") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MINS_LARGE], charsmax(g_eSettings[SETTING_MINS_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_LARGE") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_LARGE], charsmax(g_eSettings[SETTING_MAXS_LARGE]))
                        else if ( equali(szKey, "SETTING_TRIGGER_SIZE") )
                            parseSetting(DTYPE_VECTOR_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_TRIGGER_SIZE], charsmax(g_eSettings[SETTING_TRIGGER_SIZE]))
                        else if ( equali(szKey, "SETTING_FRAMERATE_MULTIPLIER") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_FRAMERATE_MULTIPLIER], charsmax(g_eSettings[SETTING_FRAMERATE_MULTIPLIER]))
                        else if ( equali(szKey, "SETTING_MAX_TARGETS") )
                            parseSetting(DTYPE_INT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_MAX_TARGETS], charsmax(g_eSettings[SETTING_MAX_TARGETS]))
                        else if ( equali(szKey, "SETTING_FAN_LOAD") )
                            parseSetting(DTYPE_BOOL, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_FAN_LOAD], charsmax(g_eSettings[SETTING_FAN_LOAD]))
                        else if ( equali(szKey, "SETTING_FAN_CHECK") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_FAN_CHECK], charsmax(g_eSettings[SETTING_FAN_CHECK]))
                        else if ( equali(szKey, "SETTING_FAN_TASK") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_FAN_TASK], charsmax(g_eSettings[SETTING_FAN_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                        else if ( equali(szKey, "SETTING_SOUND_MENU_NAV") )
                            parseSetting(DTYPE_STRING_SOUND, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_MENU_NAV], charsmax(g_eSettings[SETTING_SOUND_MENU_NAV]))
                        else if ( equali(szKey, "SETTING_SOUND_MENU_REMOVE") )
                            parseSetting(DTYPE_STRING_SOUND, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_MENU_REMOVE], charsmax(g_eSettings[SETTING_SOUND_MENU_REMOVE]))
                        else if ( equali(szKey, "SETTING_SOUND_MENU_ALERT") )
                            parseSetting(DTYPE_STRING_SOUND, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_SOUND_MENU_ALERT], charsmax(g_eSettings[SETTING_SOUND_MENU_ALERT]))
                        else if ( equali(szKey, "SETTING_COLOR_ACTIVE") )
                            parseSetting(DTYPE_VECTOR, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_COLOR_ACTIVE], charsmax(g_eSettings[SETTING_COLOR_ACTIVE]))
                        else if ( equali(szKey, "SETTING_COLOR_INACTIVE") )
                            parseSetting(DTYPE_VECTOR, szKey, charsmax(szKey), szValue, charsmax(szValue), g_eSettings[SETTING_COLOR_INACTIVE], charsmax(g_eSettings[SETTING_COLOR_INACTIVE]))
                    }
                    case SECTION_FAN:
                    {
                        if ( equali(szKey, "FAN_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_FLAGS], charsmax(eFan[FAN_FLAGS]), g_eSettings[SETTING_DEFAULT_FLAGS])
                        else if ( equali(szKey, "FAN_TEAM") )
                            parseSetting(DTYPE_INT, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_TEAM], charsmax(eFan[FAN_TEAM]), g_eSettings[SETTING_DEFAULT_TEAM])
                        else if ( equali(szKey, "FAN_SPAWN_CHANCE") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_SPAWN_CHANCE], charsmax(eFan[FAN_SPAWN_CHANCE]), g_eSettings[SETTING_DEFAULT_SPAWN_CHANCE])
                        else if ( equali(szKey, "FAN_ACTIVE_DELAY") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_ACTIVE_DELAY], charsmax(eFan[FAN_ACTIVE_DELAY]), g_eSettings[SETTING_DEFAULT_ACTIVE_DELAY])
                        else if ( equali(szKey, "FAN_ACTIVE_DURATION") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_ACTIVE_DURATION], charsmax(eFan[FAN_ACTIVE_DURATION]), g_eSettings[SETTING_DEFAULT_ACTIVE_DURATION])
                        else if ( equali(szKey, "FAN_ACTIVE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_ACTIVE_COOLDOWN], charsmax(eFan[FAN_ACTIVE_COOLDOWN]), g_eSettings[SETTING_DEFAULT_ACTIVE_COOLDOWN])
                        else if ( equali(szKey, "FAN_PUSH_STRENGTH") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_PUSH_STRENGTH], charsmax(eFan[FAN_PUSH_STRENGTH]), g_eSettings[SETTING_DEFAULT_PUSH_STRENGTH])
                        else if ( equali(szKey, "FAN_PUSH_FREQ") )
                            parseSetting(DTYPE_FLOAT_RANGE, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_PUSH_FREQ], charsmax(eFan[FAN_PUSH_FREQ]), g_eSettings[SETTING_DEFAULT_PUSH_FREQ])
                        else if ( equali(szKey, "FAN_LENGTH") )
                            parseSetting(DTYPE_FLOAT, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_LENGTH], charsmax(eFan[FAN_LENGTH]), g_eSettings[SETTING_DEFAULT_LENGTH])
                        else if ( equali(szKey, "FAN_SOUND") )
                        {
                            if ( !(eFan[FAN_FLAGS] & FLAG_SOUND) )
                            {
                                ArrayClear(eFan[FAN_SOUND])
                                eFan[FAN_FLAGS] |= FLAG_SOUND
                            }

                            parseSetting(DTYPE_ARRAY_SOUND, szKey, charsmax(szKey), szValue, charsmax(szValue), eFan[FAN_SOUND], charsmax(eFan[FAN_SOUND]), g_eSettings[SETTING_DEFAULT_SOUND])
                        }
                    }
                }
            }
        }
    }

    if ( g_iFanConfig )
        ArrayPushArray(g_aFanConfig, eFan)
    else
        set_fail_state("No Fans were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eFan[FAN], iItem
    if ( g_ePlayerData[id][PDATA_FAN_GHOST]
    && (iItem = fanGet(eFan, g_ePlayerData[id][PDATA_FAN_GHOST])) != -1 )
    {
        fanKill(eFan[FAN_ID])
        fanRemove(iItem)
    }

    DisableForwards()
    g_ePlayerData[id][PDATA_FAN_GHOST]  = 0
    g_ePlayerData[id][PDATA_FAN_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

public fanInit()
{
    if ( g_eSettings[SETTING_FAN_LOAD] )
        loadData()
}

public fanMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[64], iMenu
    formatex(szData, charsmax(szData), "%L", id, "FAN_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:   { menuRoot(id, iMenu); }
        case MENU_CREATE: { menuCreate(iMenu);      format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_ROOT_CREATE"); }
        case MENU_REMOVE: { menuRemove(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_ROOT_REMOVE"); }
        case MENU_SHOW:   { menuShow(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_ROOT_SHOW"); }
        case MENU_STATUS: { menuStatus(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_ROOT_STATUS"); }
        case MENU_ROTATE: { menuRotate(id, iMenu);  format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "FAN_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "FAN_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_STATUS")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_NOCLIP", id, get_user_noclip(id) ? "FAN_ON" : "FAN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROOT_GODMODE", id, get_user_godmode(id) ? "FAN_ON" : "FAN_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iFan >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_LIMIT", MAX_ENT)

                fanSound(id, SOUND_MENU_REMOVE)
                fanMenu(id, MENU_ROOT)
            }
            else
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_CREATE)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iFan )
            {
                client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_NO_FAN")

                fanSound(id, SOUND_MENU_REMOVE)
                fanMenu(id, MENU_ROOT)
            }
            else
            {
                fanSound(id, SOUND_MENU_REMOVE)
                fanMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_SHOW:
        {
            if ( !g_iFan )
            {
                client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_NO_FAN")

                fanSound(id, SOUND_MENU_REMOVE)
                fanMenu(id, MENU_ROOT)
            }
            else
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_SHOW)
            }
        }
        case ROOT_STATUS:
        {
            if ( !g_iFan )
            {
                client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_NO_FAN")

                fanSound(id, SOUND_MENU_REMOVE)
                fanMenu(id, MENU_ROOT)
            }
            else
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_STATUS)
            }
        }
        case ROOT_NOCLIP:
        {
            fanNoClip(id)
        }
        case ROOT_GODMODE:
        {
            fanGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eFan[FAN], szItem[64]
    for ( new i = 0; i < g_iFanConfig; i ++ )
    {
        ArrayGetArray(g_aFanConfig, i, eFan)

        copy(szItem, charsmax(szItem), eFan[FAN_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        fanSound(id, SOUND_MENU_NAV)
        fanMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    fanCreate(id, item)
    fanSound(id, SOUND_MENU_NAV)
    fanMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eFan[FAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_REMOVE_CURRENT", eFan[FAN_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    activeEnable(id)
    fanSelect(eFan, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
}

public menuHandlerRemove(id, menu, item)
{
    new eFan[FAN]
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        fanSelect(eFan, eFan[FAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] >= g_iFan - 1 )
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_FAN_MENU] ++

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_FAN_MENU] = g_iFan - 1
            else
                g_ePlayerData[id][PDATA_FAN_MENU] --

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eFan[FAN_FLAGS] &= ~FLAG_ACTIVE
            fanSetState(eFan)
            fanKill(eFan[FAN_ID])
            fanRemove(g_ePlayerData[id][PDATA_FAN_MENU])

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_REMOVE_CURRENT", eFan[FAN_NAME])
            g_ePlayerData[id][PDATA_FAN_MENU] = 0

            fanSound(id, g_iFan > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            fanMenu(id, g_iFan > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iFan )
            {
                ArrayGetArray(g_aFan, 0, eFan)
                eFan[FAN_FLAGS] &= ~FLAG_ACTIVE

                fanSetState(eFan)
                fanKill(eFan[FAN_ID])
                fanRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_FAN_MENU] = 0

            fanSound(id, SOUND_MENU_ALERT)
            fanMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_ROOT)

                activeDisable(id)
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eFan[FAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_SHOW_CURRENT",
    eFan[FAN_FLAGS] & FLAG_SHOW ? "\y" : "\r", eFan[FAN_NAME], id, eFan[FAN_FLAGS] & FLAG_SHOW ? "FAN_SHOWN" : "FAN_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    activeEnable(id)
    fanSelect(eFan, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
}

public menuHandlerShow(id, menu, item)
{
    new eFan[FAN]
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        fanSelect(eFan, eFan[FAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] >= g_iFan - 1 )
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_FAN_MENU] ++

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_FAN_MENU] = g_iFan - 1
            else
                g_ePlayerData[id][PDATA_FAN_MENU] --

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eFan[FAN_FLAGS] ^= FLAG_SHOW
            fanSetState(eFan)

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_SHOW_CURRENT",
            eFan[FAN_NAME], id, eFan[FAN_FLAGS] & FLAG_SHOW ? "FAN_CHAT_SHOWN" : "FAN_CHAT_HIDDEN")
            ArraySetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iFan; i ++ )
            {
                ArrayGetArray(g_aFan, i, eFan)
                eFan[FAN_FLAGS] |= FLAG_SHOW
                fanSetState(eFan)

                ArraySetArray(g_aFan, i, eFan)
            }

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_SHOW_ALL_SHOWN")
            fanSound(id, SOUND_MENU_ALERT)
            fanMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iFan; i ++ )
            {
                ArrayGetArray(g_aFan, i, eFan)
                eFan[FAN_FLAGS] &= ~FLAG_SHOW
                fanSetState(eFan)

                ArraySetArray(g_aFan, i, eFan)
            }

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_SHOW_ALL_HIDDEN")
            fanSound(id, SOUND_MENU_ALERT)
            fanMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_ROOT)

                activeDisable(id)
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eFan[FAN]
    menuNav(id, iMenu)
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_STATUS_CURRENT",
    eFan[FAN_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eFan[FAN_NAME], id, eFan[FAN_FLAGS] & FLAG_ACTIVE ? "FAN_ENABLED" : "FAN_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    activeEnable(id)
    fanSelect(eFan, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
}

public menuHandlerStatus(id, menu, item)
{
    new eFan[FAN]
    ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        fanSelect(eFan, eFan[FAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] >= g_iFan - 1 )
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            else
                g_ePlayerData[id][PDATA_FAN_MENU] ++

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_FAN_MENU] <= 0 )
                g_ePlayerData[id][PDATA_FAN_MENU] = g_iFan - 1
            else
                g_ePlayerData[id][PDATA_FAN_MENU] --

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eFan[FAN_FLAGS] ^= FLAG_ACTIVE
            fanSetState(eFan)

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_STATUS_CURRENT",
            eFan[FAN_NAME], id, eFan[FAN_FLAGS] & FLAG_ACTIVE ? "FAN_CHAT_ENABLED" : "FAN_CHAT_DISABLED")
            ArraySetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iFan; i ++ )
            {
                ArrayGetArray(g_aFan, i, eFan)
                eFan[FAN_FLAGS] |= FLAG_ACTIVE
                fanSetState(eFan)

                ArraySetArray(g_aFan, i, eFan)
            }

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_STATUS_ALL_ENABLED")
            fanSound(id, SOUND_MENU_ALERT)
            fanMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iFan; i ++ )
            {
                ArrayGetArray(g_aFan, i, eFan)
                eFan[FAN_FLAGS] &= ~FLAG_ACTIVE
                fanSetState(eFan)

                ArraySetArray(g_aFan, i, eFan)
            }

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_STATUS_ALL_DISABLED")
            fanSound(id, SOUND_MENU_ALERT)
            fanMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                fanSound(id, SOUND_MENU_NAV)
                fanMenu(id, MENU_ROOT)

                activeDisable(id)
                g_ePlayerData[id][PDATA_FAN_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eFan[FAN]
    if ( fanGet(eFan, g_ePlayerData[id][PDATA_FAN_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_GROUND",
    id, eFan[FAN_FLAGS] & FLAG_GROUND ? "FAN_ON" : "FAN_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "FAN_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eFan[FAN], iItem
    if ( (iItem = fanGet(eFan, g_ePlayerData[id][PDATA_FAN_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eFan[FAN_ID], pev_angles, eFan[FAN_ANGLES])
            eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eFan[FAN_ID], pev_angles, eFan[FAN_ANGLES])
            ArraySetArray(g_aFan, iItem, eFan)

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eFan[FAN_ID], pev_angles, eFan[FAN_ANGLES])
            eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eFan[FAN_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eFan[FAN_ID], pev_angles, eFan[FAN_ANGLES])
            ArraySetArray(g_aFan, iItem, eFan)

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eFan[FAN_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aFan, iItem, eFan)

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROTATE)
        }
        case ROTATE_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROTATE)
        }
        case ROTATE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_SMALL

            eFan[FAN_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eFan[FAN_SIZE] )
            {
                case SIZE_SMALL: { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_SMALL]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][0]; }
                case SIZE_MID:   { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_MID]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][1]; }
                case SIZE_LARGE: { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_LARGE]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][2]; }
            }

            ArraySetArray(g_aFan, iItem, eFan)
            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            fanTrace(eFan, id)
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_GHOST] = 0

            eFan[FAN_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eFan[FAN_FLAGS] &= ~FLAG_GHOST
            eFan[FAN_ANGLES][0] = -eFan[FAN_ANGLES][0]
            fanSetSize(eFan)
            fanSetState(eFan)
            fanSetDelay(eFan)
            ArraySetArray(g_aFan, iItem, eFan)

            client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_CREATE_NEW", eFan[FAN_NAME])
            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            fanKill(eFan[FAN_ID])
            fanRemove(iItem)
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_GHOST] = 0

            fanSound(id, SOUND_MENU_NAV)
            fanMenu(id, MENU_CREATE)
        }
        default:
        {
            fanKill(eFan[FAN_ID])
            fanRemove(iItem)
            activeDisable(id)
            g_ePlayerData[id][PDATA_FAN_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public fanTask()
{
    new eFan[FAN], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)
        bModified = false

        if ( eFan[FAN_FLAGS] & FLAG_SHOW )
        {
            if ( eFan[FAN_FLAGS] & FLAG_ACTIVE )
            {
                if ( fCurrentTime >= eFan[FAN_NEXT_PUSH] )
                {
                    fanAir(eFan)
                    eFan[FAN_NEXT_PUSH] = fCurrentTime + random_float(eFan[FAN_PUSH_FREQ][0], eFan[FAN_PUSH_FREQ][1])
                }

                if ( eFan[FAN_NEXT_DISABLE] > 0.0
                && fCurrentTime >= eFan[FAN_NEXT_DISABLE] )
                {
                    eFan[FAN_FLAGS] &= ~FLAG_ACTIVE
                    eFan[FAN_NEXT_DISABLE] = 0.0
                    eFan[FAN_NEXT_ENABLE] = fCurrentTime + random_float(eFan[FAN_ACTIVE_COOLDOWN][0], eFan[FAN_ACTIVE_COOLDOWN][1])

                    fanSetState(eFan)
                    bModified = true
                }
            }
            else
            {
                if ( eFan[FAN_NEXT_ENABLE] > 0.0
                && fCurrentTime >= eFan[FAN_NEXT_ENABLE] )
                {
                    eFan[FAN_FLAGS] |= FLAG_ACTIVE
                    eFan[FAN_NEXT_ENABLE] = 0.0
                    if ( eFan[FAN_FLAGS] & FLAG_ACTIVE_DURATION )
                        eFan[FAN_NEXT_DISABLE] = fCurrentTime + random_float(eFan[FAN_ACTIVE_DURATION][0], eFan[FAN_ACTIVE_DURATION][1])

                    fanSetState(eFan)
                    bModified = true
                }
            }
        }

        if ( bModified )
            ArraySetArray(g_aFan, i, eFan)
    }
}

stock fanCreate(id, iItem)
{
    new iEnt
    iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eFan[FAN]
    ArrayGetArray(g_aFanConfig, iItem, eFan)

    eFan[FAN_ID] = iEnt
    eFan[FAN_ITEM] = iItem
    eFan[FAN_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
    eFan[FAN_FRAMERATE] = floatclamp((eFan[FAN_PUSH_STRENGTH] / g_eSettings[SETTING_DEFAULT_BASE_STRENGTH]) * g_eSettings[SETTING_FRAMERATE_MULTIPLIER], MIN_FRAMERATE, MAX_FRAMERATE)
    if ( id )
    {
        activeEnable(id)
        g_ePlayerData[id][PDATA_FAN_GHOST] = eFan[FAN_ID]
        g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_YAW
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eFan[FAN_FLAGS] |= FLAG_GHOST
    }

    switch( eFan[FAN_SIZE] )
    {
        case SIZE_SMALL: { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_SMALL]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][0]; }
        case SIZE_MID:   { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_MID]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][1]; }
        case SIZE_LARGE: { engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_LARGE]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][2]; }
    }

    fanSelect(eFan, TARGET_GHOST)
    set_pev(iEnt, FAN_ARRAY_ITEM, g_iFan)
    set_pev(iEnt, pev_impulse, FAN_KEY)
    set_pev(iEnt, pev_classname, g_szCN)

    g_iFan ++
    ArrayPushArray(g_aFan, eFan)
    dllfunc(DLLFunc_Spawn, iEnt)
}

public fanRemove(iItem)
{
    new eFan[FAN]
    ArrayDeleteItem(g_aFan, iItem)
    g_iFan --

    for ( new i = iItem; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)
        set_pev(eFan[FAN_ID], FAN_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eFan[FAN],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_AirFans.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eFan[FAN_ITEM])
        fputs(iFile, szData)

        eFan[FAN_FLAGS] &= ~FLAG_PLAYING
        formatex(szData, charsmax(szData), "flags = %d^n", eFan[FAN_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "size = %d^n", eFan[FAN_SIZE])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eFan[FAN_ORIGIN_START][0], eFan[FAN_ORIGIN_START][1], eFan[FAN_ORIGIN_START][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eFan[FAN_ANGLES][0], eFan[FAN_ANGLES][1], eFan[FAN_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "FAN_CHAT_TAG", id, "FAN_CHAT_SAVE", szFile)
    fclose(iFile)

    fanSound(id, SOUND_MENU_NAV)
    fanMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iSize, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_AirFans.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return PLUGIN_HANDLED

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                loadDataFan(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "size") )
            {
                iSize = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        loadDataFan(iItem, iFlags, iSize, fOrigin, fAngles, iCount)

    fclose(iFile)
    return PLUGIN_HANDLED
}

stock loadDataFan(iItem, iFlags, iSize, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eFan[FAN]
    fanCreate(0, iItem)
    ArrayGetArray(g_aFan, iCount, eFan)

    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eFan[FAN_ORIGIN_START])
    xs_vec_copy(fAngles, eFan[FAN_ANGLES])

    eFan[FAN_FLAGS] = iFlags
    eFan[FAN_SIZE] = iSize
    switch( eFan[FAN_SIZE] )
    {
        case SIZE_SMALL: { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_SMALL]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][0]; }
        case SIZE_MID:   { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_MID]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][1]; }
        case SIZE_LARGE: { engfunc(EngFunc_SetModel, eFan[FAN_ID], g_eSettings[SETTING_MODEL_LARGE]); eFan[FAN_TRIGGER_SIZE] = g_eSettings[SETTING_TRIGGER_SIZE][2]; }
    }

    fanSetBox(eFan)
    fanSetSize(eFan)
    fanSetState(eFan)
    fanSetDelay(eFan)
    ArraySetArray(g_aFan, iCount, eFan)
}

public fanNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    fanSound(id, SOUND_MENU_NAV)
    fanMenu(id, MENU_ROOT)
}

public fanGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    fanSound(id, SOUND_MENU_NAV)
    fanMenu(id, MENU_ROOT)
}

public fwdUpdateClientData(id, iSendWeapons, iHandle)
{
    if ( g_ePlayerData[id][PDATA_FAN_GHOST] )
    {
        set_cd(iHandle, CD_WeaponAnim, 0)
        set_cd(iHandle, CD_flNextAttack, get_gametime() + 0.1)
    }

    return FMRES_IGNORED
}

public fwdSpawn(iEnt)
{
    if ( !isFan(iEnt) )
        return HAM_IGNORED

    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    return HAM_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eFan[FAN], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( g_ePlayerData[id][PDATA_FAN_GHOST]
    && fanGet(eFan, g_ePlayerData[id][PDATA_FAN_GHOST]) != -1 )
    {
        if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
        {
            if ( iButton & IN_ATTACK )
            {
                g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
            }
            else if ( iButton & IN_ATTACK2 )
            {
                g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
            }
        }

        iButton &= ~(IN_ATTACK | IN_ATTACK2)
        set_pev(id, pev_button, iButton)

        fanTrace(eFan, id)
    }
    else if ( g_ePlayerData[id][PDATA_FAN_ACTION] )
    {
        fanCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableForwards()
    g_ePlayerData[id][PDATA_FAN_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_FAN_GHOST] )
    {
        new eFan[FAN], iItem
        if ( (iItem = fanGet(eFan, g_ePlayerData[id][PDATA_FAN_GHOST])) != -1 )
        {
            fanKill(eFan[FAN_ID])
            fanRemove(iItem)
        }

        g_ePlayerData[id][PDATA_FAN_GHOST] = 0
    }
}

stock fanTrace(eFan[FAN], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eFan[FAN_ORIGIN_START])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eFan[FAN_ORIGIN_START], fVec1)

    engfunc(EngFunc_TraceLine, eFan[FAN_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eFan[FAN_ORIGIN_START])

    fanSetBox(eFan)
    fanSetOffset(eFan)
    set_pev(eFan[FAN_ID], pev_origin, eFan[FAN_ORIGIN_START])
}

stock fanCheck(id)
{
    new eFan[FAN], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_FAN_CHECK]
    for ( new i = 0; i < g_iFan; i ++ )
    {
        ArrayGetArray(g_aFan, i, eFan)
        xs_vec_sub(eFan[FAN_ORIGIN_START], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eFan[FAN_ID], pev_absmin, fMins)
        pev(eFan[FAN_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_FAN_MENU] != iBest )
    {
        ArrayGetArray(g_aFan, g_ePlayerData[id][PDATA_FAN_MENU], eFan)
        fanSelect(eFan, eFan[FAN_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_FAN_MENU] = iBest
        fanMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock fanSetBox(eFan[FAN])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eFan[FAN_ANGLES][0] = -eFan[FAN_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eFan[FAN_ANGLES], fForward, fRight, fUp)
    switch( eFan[FAN_SIZE] )
    {
        case SIZE_SMALL:    { xs_vec_copy(g_eSettings[SETTING_MINS_SMALL], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_SMALL], fMaxs); }
        case SIZE_MID:      { xs_vec_copy(g_eSettings[SETTING_MINS_MID], fMins);    xs_vec_copy(g_eSettings[SETTING_MAXS_MID], fMaxs); }
        case SIZE_LARGE:    { xs_vec_copy(g_eSettings[SETTING_MINS_LARGE], fMins);  xs_vec_copy(g_eSettings[SETTING_MAXS_LARGE], fMaxs); }
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eFan[FAN_MINS])
    xs_vec_copy(fMaxs, eFan[FAN_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] + fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] + fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] + fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock fanSetOffset(eFan[FAN])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eFan[FAN_MINS][0]
    fGaps[1] = eFan[FAN_MAXS][0]
    fGaps[2] = -eFan[FAN_MINS][1]
    fGaps[3] = eFan[FAN_MAXS][1]
    fGaps[4] = -eFan[FAN_MINS][2]
    fGaps[5] = eFan[FAN_MAXS][2]

    if ( eFan[FAN_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eFan[FAN_ORIGIN_START], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eFan[FAN_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, eFan[FAN_ID], 0)
        get_tr2(0, TR_vecEndPos, eFan[FAN_ORIGIN_START])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eFan[FAN_ORIGIN_START], fVec1)
        engfunc(EngFunc_TraceLine, eFan[FAN_ORIGIN_START], fVec1, DONT_IGNORE_MONSTERS, eFan[FAN_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eFan[FAN_ORIGIN_START], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eFan[FAN_ORIGIN_START], fVec1, eFan[FAN_ORIGIN_START])
        }
    }
}

stock fanSetSeq(iEnt, Float:fFrameRate = 1.0)
{
    set_pev(iEnt, pev_sequence, FAN_SEQ_SPIN)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock fanSetSize(eFan[FAN])
{
    fanSelect(eFan, TARGET_CLEAR)
    set_pev(eFan[FAN_ID], pev_solid, eFan[FAN_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eFan[FAN_ID], pev_movetype, MOVETYPE_NONE)
    set_pev(eFan[FAN_ID], pev_origin, eFan[FAN_ORIGIN_START])
    set_pev(eFan[FAN_ID], pev_angles, eFan[FAN_ANGLES])

    eFan[FAN_ANGLES][0] = -eFan[FAN_ANGLES][0]
    engfunc(EngFunc_SetSize, eFan[FAN_ID], eFan[FAN_MINS], eFan[FAN_MAXS])
    engfunc(EngFunc_AngleVectors, eFan[FAN_ANGLES], NULL_VECTOR, NULL_VECTOR, eFan[FAN_DIRECTION])
    ArrayGetString(eFan[FAN_SOUND], random(ArraySize(eFan[FAN_SOUND])), eFan[FAN_SOUND_CURRENT], charsmax(eFan[FAN_SOUND_CURRENT]))
    fanLength(eFan)
}

stock fanLength(eFan[FAN])
{
    xs_vec_mul_scalar(eFan[FAN_DIRECTION], eFan[FAN_LENGTH], eFan[FAN_ORIGIN_END])
    xs_vec_add(eFan[FAN_ORIGIN_START], eFan[FAN_ORIGIN_END], eFan[FAN_ORIGIN_END])

    engfunc(EngFunc_TraceLine, eFan[FAN_ORIGIN_START], eFan[FAN_ORIGIN_END], IGNORE_MONSTERS, eFan[FAN_ID], 0)
    get_tr2(0, TR_vecEndPos, eFan[FAN_ORIGIN_END])
}

stock fanSetState(eFan[FAN])
{
    if ( eFan[FAN_FLAGS] & FLAG_SHOW )
    {
        fanSelect(eFan, TARGET_CLEAR)
        set_pev(eFan[FAN_ID], pev_solid, SOLID_BBOX)

        if ( eFan[FAN_FLAGS] & FLAG_ACTIVE )
        {
            fanSetSeq(eFan[FAN_ID], eFan[FAN_FRAMERATE])
            if ( !(eFan[FAN_FLAGS] & FLAG_PLAYING) )
            {
                eFan[FAN_FLAGS] |= FLAG_PLAYING
                engfunc(EngFunc_EmitAmbientSound, eFan[FAN_ID], CHAN_ITEM, eFan[FAN_SOUND_CURRENT], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            }
        }
        else
        {
            fanSetSeq(eFan[FAN_ID], 0.0)
            if ( eFan[FAN_FLAGS] & FLAG_PLAYING )
            {
                eFan[FAN_FLAGS] &= ~FLAG_PLAYING
                engfunc(EngFunc_EmitAmbientSound, eFan[FAN_ID], CHAN_ITEM, eFan[FAN_SOUND_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
            }
        }
    }
    else
    {
        fanSelect(eFan, TARGET_HIDE)
        fanSetSeq(eFan[FAN_ID], 0.0)
        set_pev(eFan[FAN_ID], pev_solid, SOLID_NOT)

        if ( eFan[FAN_FLAGS] & FLAG_PLAYING )
        {
            eFan[FAN_FLAGS] &= ~FLAG_PLAYING
            engfunc(EngFunc_EmitAmbientSound, eFan[FAN_ID], CHAN_ITEM, eFan[FAN_SOUND_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
        }
    }
}

stock fanSetDelay(eFan[FAN])
{
    if ( eFan[FAN_FLAGS] & FLAG_ACTIVE )
    {
        new Float:fCurrentTime
        fCurrentTime = get_gametime()

        if ( eFan[FAN_FLAGS] & FLAG_ACTIVE_DELAY )
        {
            eFan[FAN_FLAGS] &= ~FLAG_ACTIVE
            eFan[FAN_NEXT_ENABLE] = fCurrentTime + random_float(eFan[FAN_ACTIVE_DELAY][0], eFan[FAN_ACTIVE_DELAY][1])

            fanSetState(eFan)
        }
        else
        {
            if ( eFan[FAN_FLAGS] & FLAG_ACTIVE_DURATION )
                eFan[FAN_NEXT_DISABLE] = fCurrentTime + random_float(eFan[FAN_ACTIVE_DURATION][0], eFan[FAN_ACTIVE_DURATION][1])
        }
    }
}

stock fanAir(eFan[FAN])
{
    new Float:fOrigin[3], iEnt, iTarget
    for ( new i = 0; i < sizeof(g_szPushClasses) && iTarget < g_eSettings[SETTING_MAX_TARGETS]; i ++ )
    {
        iEnt = 0
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", g_szPushClasses[i])) )
        {
            if ( !pev_valid(iEnt)
            || eFan[FAN_ID] == iEnt
            || pev(iEnt, pev_solid) == SOLID_NOT
            || pev(iEnt, pev_movetype) == MOVETYPE_NONE
            || pev(iEnt, pev_movetype) == MOVETYPE_FOLLOW
            || (eFan[FAN_FLAGS] & FLAG_PLAYERS_ONLY && !is_user_alive(iEnt))
            || (is_user_alive(iEnt) && !(CsTeams:eFan[FAN_TEAM] & cs_get_user_team(iEnt)))  )
                continue

            pev(iEnt, pev_origin, fOrigin)
            if ( !isFanActive(eFan, fOrigin) )
                continue

            fanPush(eFan, iEnt)
            if ( ++ iTarget >= g_eSettings[SETTING_MAX_TARGETS] )
                break
        }
    }
}

stock bool:isFanActive(eFan[FAN], Float:fOrigin[3])
{
    new Float:fVec1[3]
    xs_vec_sub(fOrigin, eFan[FAN_ORIGIN_START], fVec1)
    new Float:fDot = xs_vec_dot(eFan[FAN_DIRECTION], fVec1)

    if ( fDot < 0.0 || fDot > eFan[FAN_LENGTH] )
        return false

    xs_vec_mul_scalar(eFan[FAN_DIRECTION], fDot, fVec1)
    xs_vec_add(eFan[FAN_ORIGIN_START], fVec1, fVec1)
    if ( get_distance_f(fOrigin, fVec1) > eFan[FAN_TRIGGER_SIZE] )
        return false

    return true
}

stock fanPush(eFan[FAN], iEnt)
{
    new Float:fVelocity[3], Float:fPush[3]
    pev(iEnt, pev_velocity, fVelocity)
    xs_vec_mul_scalar(eFan[FAN_DIRECTION], eFan[FAN_PUSH_STRENGTH], fPush)

    xs_vec_add(fVelocity, fPush, fVelocity)
    set_pev(iEnt, pev_velocity, fVelocity)
}

stock fanSelect(eFan[FAN], iAction)
{
    new iRender, iRenderFx, iRenderColor[3], iRenderAmt

    iRenderFx = kRenderFxNone
    if ( iAction == TARGET_SELECT )
    {
        if ( eFan[FAN_FLAGS] & FLAG_ACTIVE ) { iRenderColor[0] = g_eSettings[SETTING_COLOR_ACTIVE][0];      iRenderColor[1] = g_eSettings[SETTING_COLOR_ACTIVE][1];     iRenderColor[2] = g_eSettings[SETTING_COLOR_ACTIVE][2]; }
        else                                 { iRenderColor[0] = g_eSettings[SETTING_COLOR_INACTIVE][0];    iRenderColor[1] = g_eSettings[SETTING_COLOR_INACTIVE][1];   iRenderColor[2] = g_eSettings[SETTING_COLOR_INACTIVE][2]; }

        iRender = kRenderTransColor
        iRenderFx = kRenderFxGlowShell
        iRenderAmt = 16
    }
    else if ( iAction == TARGET_GHOST )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = g_eSettings[SETTING_GHOST_ALPHA]
    }
    else if ( iAction == TARGET_HIDE )
    {
        iRender = kRenderTransAlpha
        iRenderAmt = 0
    }
    else if ( iAction == TARGET_CLEAR )
    {
        iRender = kRenderNormal
        iRenderAmt = 255
    }

    set_ent_rendering(eFan[FAN_ID], iRenderFx, iRenderColor[0], iRenderColor[1], iRenderColor[2], iRender, iRenderAmt)
}

stock fanSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_NAV])
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_REMOVE])
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), g_eSettings[SETTING_SOUND_MENU_ALERT])
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock fanReset(eFan[FAN])
{
    eFan[FAN_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
    eFan[FAN_NEXT_ENABLE] = 0.0
    eFan[FAN_NEXT_DISABLE] = 0.0
    eFan[FAN_NEXT_PUSH] = 0.0

    fanSetState(eFan)
}

stock activeEnable(id)
{
    if ( !g_ePlayerData[id][PDATA_FAN_ACTION] )
    {
        new eFan[FAN]
        for ( new i = 0; i < g_iFan; i ++ )
        {
            ArrayGetArray(g_aFan, i, eFan)
            if ( eFan[FAN_FLAGS] & FLAG_SHOW )
                continue

            fanSelect(eFan, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_FAN_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForwards()
    }
}

stock activeDisable(id)
{
    if ( g_ePlayerData[id][PDATA_FAN_ACTION] )
    {
        new eFan[FAN]
        for ( new i = 0; i < g_iFan; i ++ )
        {
            ArrayGetArray(g_aFan, i, eFan)
            if ( eFan[FAN_FLAGS] & FLAG_SHOW )
                continue

            fanSelect(eFan, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_FAN_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForwards()
    }
}

stock EnableForwards()
{
    g_iFwdUpdateClientData = register_forward(FM_UpdateClientData, "fwdUpdateClientData", 1)
    EnableHamForward(g_iFwdSpawn)
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForwards()
{
    unregister_forward(FM_UpdateClientData, g_iFwdUpdateClientData, 1)
    DisableHamForward(g_iFwdSpawn)
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock fanGet(eFan[FAN], iEnt)
{
    new iItem
    iItem = pev(iEnt, FAN_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iFan )
        return -1

    ArrayGetArray(g_aFan, iItem, eFan)
    return iItem
}

stock bool:isFan(iEnt)
{
    return pev(iEnt, pev_impulse) == FAN_KEY
}

stock fanKill(iEnt)
{
    if (pev_valid(iEnt))
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szKey[], iKeyLen, szValue[], iValueLen, any:output[], iOutputLen, const any:fallback[] = {0.0, 0.0})
{
    switch ( iType )
    {
        case DTYPE_FLOAT_RANGE:
        {
            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[0] = str_to_float(szKey)
            output[1] = str_to_float(szValue)

            if ( output[0] < 0.0 ) output[0] = fallback[0]
            if ( output[1] < 0.0 ) output[1] = fallback[1]
        }
        case DTYPE_FLOAT:
        {
            output[0] = str_to_float(szValue)
            if ( output[0] < 0.0 ) output[0] = fallback[0]
        }
        case DTYPE_INT_RANGE:
        {
            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[0] = str_to_num(szKey)
            output[1] = str_to_num(szValue)

            if ( output[0] < 0 ) output[0] = fallback[0]
            if ( output[1] < 0 ) output[1] = fallback[1]
        }
        case DTYPE_INT:
        {
            output[0] = str_to_num(szValue)
            if ( output[0] < 0 ) output[0] = fallback[0]
        }
        case DTYPE_BOOL:
        {
            output[0] = bool:str_to_num(szValue)
        }
        case DTYPE_FLAGS:
        {
            output[0] = read_flags(szValue)
        }
        case DTYPE_VECTOR:
        {
            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[0] = str_to_num(szKey)

            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[1] = str_to_num(szKey)
            output[2] = str_to_num(szValue)
        }
        case DTYPE_VECTOR_FLOAT:
        {
            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[0] = str_to_float(szKey)

            strtok(szValue, szKey, iKeyLen, szValue, iValueLen, ' ')
            output[1] = str_to_float(szKey)
            output[2] = str_to_float(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(output[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(output[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(output, iOutputLen, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(output, iOutputLen, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                output[0] = precache_model(szValue)
        }
    }
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}


