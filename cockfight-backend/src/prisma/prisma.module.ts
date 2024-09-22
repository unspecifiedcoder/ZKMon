import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

/**
 * Module for initiating Prisma-Postgres Connection
 * and exporting Prisma Service globally for it to get injected in all modules
 */
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
