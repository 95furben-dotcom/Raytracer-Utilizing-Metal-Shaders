import subprocess

rootPath = "/Users/benjaminflynnfurnes/Documents/CppProjects/MetalProjects/RayTracers/Raytracer_V6/"

def run(command : str, relativePath : str = "") -> None:
    cmd = command.split(" ")
    cwd = rootPath+relativePath
    result = subprocess.run(cmd,cwd=cwd,capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Command failed: {' '.join(cmd)}\ncwd={cwd}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}")
        exit(result.returncode)
    else:
        # Show useful output when successful
        if result.stdout.strip():
            print(result.stdout)
        else:
            print(f"{relativePath.split('/')[-1]} compile success")


# compile shaders
# compile each .metal -> .air
shderDir = "shaders/"
shaders = ["common", "random","raytracing", "main"]
for shader in shaders:
    print(f"Compiling shader: {shader}")
    run(f"xcrun -sdk macosx metal -c {shader}.metal -o compiles/{shader}.air", shderDir)

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