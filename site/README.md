```
   _____________________
  /                    /|
 /                    / |   foldtint
/____________________/  |
|                    | /
|    [ Locked ]      |/
|____________________|
```

# foldtint site

Static site for foldtint. The page states what the tool does, shows a Desktop preview, and lists the commands from the project README.

## Run

```
cd site
npm install
npm run dev
```

## Build

```
cd site
npm install
npm run build
npm run preview
```

The build writes a static Vite app to `dist`.

## Test

```
cd site
npm install
npx playwright install chromium
npm test
```

The tests run against `vite preview`.
