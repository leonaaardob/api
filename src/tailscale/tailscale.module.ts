import { Module } from "@nestjs/common";
import { TailscaleService } from "./tailscale.service";

@Module({
  providers: [TailscaleService],
  exports: [TailscaleService],
})
export class TailscaleModule {}
