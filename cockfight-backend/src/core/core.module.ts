import { Module } from '@nestjs/common';
import { CoreController } from './core.controller';
import { CoreService } from './core.service';

/**
 * MODULE to take care of query and muation of backed aspect
 */
@Module({
  controllers: [CoreController],
  providers: [CoreService],
})
export class CoreModule {}
