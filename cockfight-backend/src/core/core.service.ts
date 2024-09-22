import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class CoreService {
  constructor(private postgre: PrismaService, private config: ConfigService) {}
}
