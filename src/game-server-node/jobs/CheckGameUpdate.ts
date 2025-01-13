import { WorkerHost } from "@nestjs/bullmq";
import { CacheService } from "../../cache/cache.service";
import { UseQueue } from "../../utilities/QueueProcessors";
import { GameServerQueues } from "../enums/GameServerQueues";
import { Logger } from "@nestjs/common";
import { GameServerNodeService } from "../game-server-node.service";
import { HasuraService } from "src/hasura/hasura.service";

@UseQueue("GameServerNode", GameServerQueues.GameUpdate)
export class CheckGameUpdate extends WorkerHost {
  constructor(
    protected readonly cache: CacheService,
    protected readonly logger: Logger,
    protected readonly gameServerNodeService: GameServerNodeService,
    protected readonly hasuraService: HasuraService,
  ) {
    super();
  }

  async process(): Promise<void> {
    const response = await fetch("https://api.steamcmd.net/v1/info/730");
    const latestBuildTime = await this.cache.get("cs:updated-at");

    const { data } = await response.json();

    const publicBuild = data["730"].depots?.branches?.public;

    if (!publicBuild) {
      return;
    }

    await this.hasuraService.mutation({
      insert_settings_one: {
        __args: {
          object: {
            name: "cs_version",
            value: JSON.stringify(publicBuild),
          },
          on_conflict: {
            constraint: "settings_pkey",
            update_columns: ["value"],
          },
        },
        __typename: true,
      },
    });

    if (
      !latestBuildTime ||
      latestBuildTime < parseInt(publicBuild.timeupdated)
    ) {
      await this.cache.put("cs:updated-at", parseInt(publicBuild.timeupdated));

      await this.gameServerNodeService.updateCs();
    }
  }
}
