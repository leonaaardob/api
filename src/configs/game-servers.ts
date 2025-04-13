import { GameServersConfig } from "./types/GameServersConfig";

export default (): {
  gameServers: GameServersConfig;
} => ({
  gameServers: {
    serverImage:
      process.env.SERVER_IMAGE || "ghcr.io/leonaaardob/game-server:latest",
    namespace: "5stack",
  },
});
