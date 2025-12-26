import subprocess

rootPath = "/Users/benjaminflynnfurnes/Documents/CppProjects/MetalProjects/RayTracers/Minecraft_1.1.1/"

def run(command : str, relativePath : str = "") -> None:
    cmd = command.split(" ")
    cwd = rootPath+relativePath
    result = subprocess.run(cmd,cwd=cwd,capture_output=True, text=True)

    if result.returncode != 0:
        print("❌ Shader compile failed:")
        exit(result.stderr)
    else:
        if result.stderr.strip():
            print("⚠️ Warnings:")
            print(result.stderr)
        print("✅ Success")

    return result.returncode


# compile shaders
# compile each .metal -> .air
shderDir = "shaders/"
shaders = ["common", "random","raytracing", "main"]
for shader in shaders:
    print(f"Compiling shader: {shader}")
    run(
    f"xcrun -sdk macosx metal "
#    f"-Wall -Werror " # treat all warnings as errors
    f"-std=metal3.0 "
    f"-Winvalid-offsetof "
    f"-c {shader}.metal -o compiles/{shader}.air",
    shderDir
)


# link .air -> .metallib
compilesDir = "shaders/compiles/"
airShaders = str.join(" ",[f"{shader}.air" for shader in shaders])
print("air shaders: ", airShaders)

run(f"xcrun -sdk macosx metallib {airShaders} -o compiledShader.metallib", compilesDir)


# compile app 
print("Compiling app")
mmFiles = ["main.mm", "Renderer/Renderer.mm", "Settings/SettingsLoader.mm"]
run(f"clang++ -std=c++17 -framework Cocoa -framework Metal -framework MetalKit {str.join(" ",mmFiles)} -o MetalApp")



# run

def runApp():
    print("Running app")

    # Launch the app detached and don't open a Terminal window (open with -g for background)
    subprocess.Popen(["open", "-g", "./MetalApp"], cwd=rootPath,
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL,
                    close_fds=True)

    print("Launched MetalApp (background)")