import EsoEnvironment

    # Modify below constants to point to relevant files/paths
INPUT_GLOBAL_FILENAME = "d:\\esoexport\\goodimages10\\globals_6b.txt"
INPUT_LUA_PATH = "d:\\esoexport\\gamemnf10\\esoui\\"
OUTPUT_PATH = "d:\\temp\\esodata\\"

esoEnvironment = EsoEnvironment.CEsoEnvironment()
esoEnvironment.LoadGlobals(INPUT_GLOBAL_FILENAME)
esoEnvironment.LoadLuaFiles(INPUT_LUA_PATH)
esoEnvironment.CreateAll(OUTPUT_PATH)

