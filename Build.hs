import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="_build"} $ do
    want ["_build/run" <.> exe]

    phony "clean" $ do
        putNormal "Cleaning files in _build"
        removeFilesAfter "_build" ["//*"]
        removeFilesAfter "." ["foo.h"]

    phony "gen_header" $ do
        cmd "/bin/sh ./header_gen.sh"

    "_build/run" <.> exe %> \out -> do
        need ["foo.h"]
        cs <- getDirectoryFiles "" ["//*.cpp"]
        let os = ["_build" </> c -<.> "o" | c <- cs]
        need os
        cmd "g++ -o" [out] os

    "_build//*.o" %> \out -> do
        let c = dropDirectory1 $ out -<.> "cpp"
        let dep = out -<.> "dep"
        () <- cmd "g++ -c" [c] "-o" [out] "-MMD -MF" [dep]
        needMakefileDependencies dep

    "foo.h" %> \out -> do
        alwaysRerun
        need ["header_gen.sh"]
        cmd "/bin/sh ./header_gen.sh"
